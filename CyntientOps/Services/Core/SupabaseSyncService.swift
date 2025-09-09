//
//  SupabaseSyncService.swift
//  CyntientOps
//
//  Pushes local conversations and usage analytics to Supabase (JWT pass‑through when available).
//

import Foundation

@MainActor
public final class SupabaseSyncService: ObservableObject {
    public static let shared = SupabaseSyncService()
    private init() {}

    private let db = GRDBManager.shared

    // MARK: - Public API

    public func queueConversation(userId: String, userRole: String, prompt: String, response: String, contextJSON: String?, model: String?, tokens: Int?, latencyMs: Int?) async {
        do {
            let id = UUID().uuidString
            try await db.execute("""
                INSERT INTO conversations_local (id, user_id, user_role, prompt, response, context_data, processing_time_ms, model_used, synced, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
            """, [
                id, userId, userRole, prompt, response,
                contextJSON ?? NSNull(),
                latencyMs ?? NSNull(),
                model ?? NSNull(),
                ISO8601DateFormatter().string(from: Date())
            ])
            await syncConversations()
        } catch {
            print("⚠️ Failed to queue conversation: \(error)")
        }
    }

    public func queueUsage(userId: String, promptType: String, mode: String, tokens: Int?, latencyMs: Int?, success: Bool, errorMessage: String?) async {
        do {
            let id = UUID().uuidString
            try await db.execute("""
                INSERT INTO nova_usage_analytics_local (id, user_id, prompt_type, processing_mode, tokens_used, latency_ms, success, error, synced, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
            """, [
                id, userId, promptType, mode, tokens ?? 0, latencyMs ?? NSNull(), success ? 1 : 0, errorMessage ?? NSNull(), ISO8601DateFormatter().string(from: Date())
            ])
            await syncUsage()
        } catch {
            print("⚠️ Failed to queue usage analytics: \(error)")
        }
    }

    public func syncAll() async {
        await syncConversations()
        await syncUsage()
    }

    // MARK: - Sync Implementations

    private func supabaseBaseURL() -> URL? {
        guard let base = ProcessInfo.processInfo.environment["SUPABASE_URL"], !base.isEmpty else { return nil }
        return URL(string: base.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    private func buildRequest(path: String, method: String = "POST") -> URLRequest? {
        guard let base = supabaseBaseURL() else { return nil }
        guard let url = URL(string: path, relativeTo: base) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let anon = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !anon.isEmpty {
            req.setValue(anon, forHTTPHeaderField: "apikey")
        }
        // Prefer secure JWT from the authenticated session
        let jwt = NewAuthManager.shared.accessToken
        if let token = jwt, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let anon = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !anon.isEmpty {
            req.setValue("Bearer \(anon)", forHTTPHeaderField: "Authorization")
        }
        // Ask Supabase to return inserted rows
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        return req
    }

    private func syncConversations() async {
        guard let requestBase = buildRequest(path: "/rest/v1/conversations") else { return }
        do {
            let rows = try await db.query("""
                SELECT id, user_id, user_role, prompt, response, context_data, processing_time_ms, model_used, created_at
                FROM conversations_local WHERE synced = 0 ORDER BY created_at ASC LIMIT 50
            """)
            for row in rows {
                var req = requestBase
                let payload: [String: Any?] = [
                    "user_id": row["user_id"],
                    "user_role": row["user_role"],
                    "prompt": row["prompt"],
                    "response": row["response"],
                    "context_data": (row["context_data"] as? String).flatMap { try? JSONSerialization.jsonObject(with: Data($0.utf8)) } ?? nil,
                    "processing_time_ms": row["processing_time_ms"],
                    "model_used": row["model_used"]
                ]
                req.httpBody = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 })
                let (_, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse else { continue }
                if 200...299 ~= http.statusCode {
                    try await db.execute("UPDATE conversations_local SET synced = 1 WHERE id = ?", [row["id"] as? String ?? ""])
                } else {
                    // Stop on unauthorized to avoid hammering
                    if http.statusCode == 401 || http.statusCode == 403 { break }
                }
            }
        } catch {
            // Network or DB error — keep for later
        }
    }

    private func syncUsage() async {
        guard let requestBase = buildRequest(path: "/rest/v1/nova_usage_analytics") else { return }
        do {
            let rows = try await db.query("""
                SELECT id, user_id, prompt_type, processing_mode, tokens_used, latency_ms, success, error, created_at
                FROM nova_usage_analytics_local WHERE synced = 0 ORDER BY created_at ASC LIMIT 100
            """)
            for row in rows {
                var req = requestBase
                let payload: [String: Any?] = [
                    "user_id": row["user_id"],
                    "prompt_type": row["prompt_type"],
                    "processing_mode": row["processing_mode"],
                    "tokens_used": row["tokens_used"],
                    "response_quality": NSNull(),
                    "created_at": row["created_at"]
                ]
                req.httpBody = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 })
                let (_, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse else { continue }
                if 200...299 ~= http.statusCode {
                    try await db.execute("UPDATE nova_usage_analytics_local SET synced = 1 WHERE id = ?", [row["id"] as? String ?? ""])
                } else {
                    if http.statusCode == 401 || http.statusCode == 403 { break }
                }
            }
        } catch {
            // Keep for next time
        }
    }
}

