# 🚀 **Nova AI - Supabase Integration Setup Guide**

## Overview

This guide will walk you through setting up Supabase to power Nova AI with real LLM capabilities. The current implementation has hybrid online/offline support - this setup enables the full online intelligence.

## Architecture

```
CyntientOps App → Supabase Edge Function → OpenAI/LLM → Response
       ↑                                                      ↓
   Local Cache ←←←←←← Conversation History Database ←←←←←←←←←
```

---

## **PART 1: Supabase Project Setup**

### Step 1: Create Supabase Project

1. **Sign up/Login** to [Supabase](https://supabase.com)
2. **Create New Project**:
   - Project Name: `CyntientOps-Nova-AI`
   - Database Password: `[Generate Strong Password]`
   - Region: Choose closest to your users

3. **Wait for project initialization** (2-3 minutes)

### Step 2: Create Database Tables

1. **Open SQL Editor** in your Supabase dashboard
2. **Run this SQL** to create conversation history table:

```sql
-- Conversation history for Nova AI context
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    user_role TEXT NOT NULL DEFAULT 'worker',
    prompt TEXT NOT NULL,
    response TEXT,
    context_data JSONB,
    processing_time_ms INTEGER,
    model_used TEXT DEFAULT 'gpt-4',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Create policy for users to access only their conversations
CREATE POLICY "Users can access their own conversations" ON conversations
    FOR ALL USING (auth.uid()::text = user_id);

-- Create index for faster queries
CREATE INDEX conversations_user_created_idx ON conversations (user_id, created_at DESC);
CREATE INDEX conversations_user_role_idx ON conversations (user_id, user_role);

-- Nova AI insights cache (mirrors local database)
CREATE TABLE nova_insights_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insight_id TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    insight_type TEXT NOT NULL,
    priority TEXT NOT NULL,
    building_id TEXT,
    category TEXT,
    context_data JSONB,
    confidence_score REAL DEFAULT 1.0,
    user_id TEXT NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for insights
ALTER TABLE nova_insights_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own insights" ON nova_insights_cache
    FOR ALL USING (auth.uid()::text = user_id);

-- Usage analytics for Nova AI
CREATE TABLE nova_usage_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    prompt_type TEXT NOT NULL,
    response_quality INTEGER, -- 1-5 rating
    processing_mode TEXT NOT NULL, -- 'online' or 'offline'
    tokens_used INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE nova_usage_analytics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access their own usage data" ON nova_usage_analytics
    FOR ALL USING (auth.uid()::text = user_id);
```

### Step 3: Configure API Keys

1. **Go to Project Settings** → **API**
2. **Copy these values** (you'll need them later):
   - `Project URL`: `https://[your-project-ref].supabase.co`
   - `Anon Key`: `eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...`

---

## **PART 2: LLM Provider Setup (OpenAI)**

### Step 1: Get OpenAI API Key

1. **Sign up/Login** to [OpenAI](https://platform.openai.com)
2. **Go to API Keys** → **Create new secret key**
3. **Copy the key** (starts with `sk-...`)
4. **Set usage limits** in your OpenAI account for cost control

### Step 2: Add Environment Variables to Supabase

1. **Go to Project Settings** → **Edge Functions** → **Environment Variables**
2. **Add these variables**:

```
OPENAI_API_KEY=sk-your-actual-openai-key-here
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

---

## **PART 3: Edge Function Deployment**

### Step 1: Install Supabase CLI

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login
```

### Step 2: Create Edge Function

1. **Initialize Supabase locally** in your project directory:
```bash
cd /path/to/your/CyntientOps
supabase init
```

2. **Create the Nova AI Edge Function**:
```bash
supabase functions new nova-ai-processor
```

3. **Replace the content** of `supabase/functions/nova-ai-processor/index.ts`:

```typescript
// supabase/functions/nova-ai-processor/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { prompt, history, userRole, context } = await req.json();
    
    // Validate required environment variables
    const openAIApiKey = Deno.env.get("OPENAI_API_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!openAIApiKey) {
      throw new Error('OpenAI API key not configured');
    }

    console.log(`🧠 Processing Nova prompt for ${userRole}: ${prompt.substring(0, 50)}...`);

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl!, supabaseKey!);

    // Construct messages with Nova AI persona and context
    const systemMessage = {
      role: "system",
      content: `You are Nova, an intelligent AI assistant for CyntientOps, a building management application. 

You help ${userRole}s with:
- Task management and scheduling
- Building maintenance operations
- Compliance tracking and reporting
- Performance analytics and insights
- Strategic recommendations

Current context: ${JSON.stringify(context)}

Respond professionally but in a conversational tone. Use emojis sparingly and only when they enhance clarity. Keep responses focused and actionable.`
    };

    const messages = [
      systemMessage,
      ...history, // Previous conversation context
      { role: "user", content: prompt },
    ];

    // Call OpenAI API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openAIApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: "gpt-4",
        messages: messages,
        max_tokens: 500,
        temperature: 0.7,
        presence_penalty: 0.1,
        frequency_penalty: 0.1,
      }),
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new Error(`OpenAI API error: ${response.status} - ${errorData}`);
    }

    const data = await response.json();
    const responseText = data.choices[0].message.content;

    // Store conversation in database
    const { error: dbError } = await supabase
      .from('conversations')
      .insert({
        user_id: req.headers.get('user-id') || 'anonymous',
        user_role: userRole || 'worker',
        prompt: prompt,
        response: responseText,
        context_data: context,
        processing_time_ms: Date.now() - startTime,
        model_used: 'gpt-4'
      });

    if (dbError) {
      console.error('Failed to store conversation:', dbError);
      // Don't fail the request if storage fails
    }

    console.log(`✅ Nova response generated successfully`);

    return new Response(
      JSON.stringify({ 
        success: true,
        response: responseText,
        model: 'gpt-4',
        tokensUsed: data.usage?.total_tokens || 0
      }),
      { 
        headers: { 
          ...corsHeaders,
          "Content-Type": "application/json" 
        } 
      }
    );

  } catch (error) {
    console.error('❌ Nova processing error:', error.message);
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message,
        fallbackResponse: "I'm experiencing technical difficulties. Please try again or use offline mode."
      }),
      { 
        status: 500,
        headers: { 
          ...corsHeaders,
          "Content-Type": "application/json" 
        } 
      }
    );
  }
});
```

### Step 3: Deploy Edge Function

```bash
# Deploy the function
supabase functions deploy nova-ai-processor --no-verify-jwt

# Test the function (optional)
supabase functions invoke nova-ai-processor --data '{"prompt":"Hello Nova", "userRole":"admin", "history":[], "context":{}}'
```

---

## **PART 4: iOS App Integration**

### Step 1: Add Supabase Configuration

1. **Open your iOS project**
2. **Add to `Configuration/Credentials.swift`**:

```swift
// Add these to your Credentials.swift
struct SupabaseCredentials {
    static let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] 
                     ?? "https://your-project-ref.supabase.co"
    static let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] 
                         ?? "your-anon-key-here"
}
```

### Step 2: Update NovaAPIService 

Note: In this repository, Nova already uses secure JWT pass‑through.
- App side: `Nova/Core/NovaAPIService.swift` sets `Authorization: Bearer <sessionJWT>` when available (falls back to anon only if no token; disable that fallback for production).
- Sync side: `Services/Core/SupabaseSyncService.swift` includes the user JWT on REST writes so RLS policies apply.
- Server side: Your Edge Function must create the Supabase client with the incoming Authorization header so `auth.uid()` is populated (do not deploy with `--no-verify-jwt`). See Step 3 above for secure deploy and the TypeScript example.

The example below shows a generic pattern; prefer the in‑repo implementation paths referenced above.

The `processPromptOnline` method in `NovaAPIService.swift` is already set up with a placeholder. **Replace the TODO section** with:

```swift
/// Process prompt when online - calls Supabase Edge Function
private func processPromptOnline(_ prompt: NovaPrompt) async throws -> NovaResponse {
    let startTime = Date()
    
    // Supabase Edge Function URL
    guard let url = URL(string: "\(SupabaseCredentials.url)/functions/v1/nova-ai-processor") else {
        throw NovaAPIError.invalidConfiguration
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(SupabaseCredentials.anonKey)", forHTTPHeaderField: "Authorization")
    
    // Get conversation history (last 5 messages)
    let history = await getConversationHistory(limit: 5)
    
    // Prepare request body
    let requestBody: [String: Any] = [
        "prompt": prompt.text,
        "history": history,
        "userRole": getCurrentUserRole(),
        "context": await buildContextForPrompt(prompt)
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    
    do {
        print("🌐 Nova: Calling Supabase Edge Function...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NovaAPIError.serviceUnavailable
        }
        
        if httpResponse.statusCode != 200 {
            print("❌ Supabase Edge Function error: \(httpResponse.statusCode)")
            throw NovaAPIError.serviceUnavailable
        }
        
        let decodedResponse = try JSONDecoder().decode(SupabaseResponse.self, from: data)
        
        if decodedResponse.success {
            let processingTime = Date().timeIntervalSince(startTime)
            print("✅ Nova: Online response generated in \(processingTime)s")
            
            return NovaResponse(
                success: true,
                message: decodedResponse.response,
                context: prompt.context,
                metadata: [
                    "mode": "online",
                    "model": decodedResponse.model ?? "gpt-4",
                    "tokensUsed": String(decodedResponse.tokensUsed ?? 0),
                    "processingTime": String(processingTime)
                ]
            )
        } else {
            print("❌ Nova: Edge function reported error: \(decodedResponse.error ?? "unknown")")
            // Fall back to offline processing
            return await processPromptOffline(prompt)
        }
        
    } catch {
        print("❌ Nova: Network request failed: \(error)")
        // Fall back to offline processing
        return await processPromptOffline(prompt)
    }
}

// Helper struct for Supabase response
private struct SupabaseResponse: Decodable {
    let success: Bool
    let response: String
    let model: String?
    let tokensUsed: Int?
    let error: String?
    let fallbackResponse: String?
}

// Helper methods you'll need to implement
private func getConversationHistory(limit: Int) async -> [[String: String]] {
    // Return recent conversation history from local storage
    // This helps provide context to the LLM
    return []
}

private func getCurrentUserRole() -> String {
    // Return current user's role (admin, worker, client)
    return "worker" // Placeholder
}

private func buildContextForPrompt(_ prompt: NovaPrompt) async -> [String: Any] {
    // Build context object with current app state
    return [
        "timestamp": ISO8601DateFormatter().string(from: Date()),
        "userRole": getCurrentUserRole(),
        "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    ]
}
```

### Step 3: Add Environment Variables to Xcode

1. **Create `.xcconfig` file** (add to `.gitignore`):
```
// Config/Development.xcconfig
SUPABASE_URL = https://@(your-project-ref).supabase.co
SUPABASE_ANON_KEY = your-anon-key-here
```

2. **Add to your target's build settings**:
   - Add the xcconfig file to your project
   - Set the environment variables

---

## **PART 5: Testing & Monitoring**

### Step 1: Test the Integration

1. **Test Offline Mode**:
   - Turn off WiFi/cellular in iOS Simulator
   - Ask Nova questions like "What are my tasks?"
   - Should get local database responses

2. **Test Online Mode**:
   - Turn on network connectivity
   - Ask Nova complex questions like "Analyze my portfolio performance"
   - Should get LLM-powered responses

### Step 2: Monitor Usage

1. **Supabase Dashboard** → **Table Editor** → **conversations**
   - View conversation history
   - Monitor response times

2. **OpenAI Dashboard** → **Usage**
   - Track token consumption
   - Monitor costs

3. **Edge Function Logs**:
```bash
supabase functions logs nova-ai-processor
```

---

## **PART 6: Cost Management**

### OpenAI Cost Controls

1. **Set usage limits** in OpenAI dashboard
2. **Monitor token usage** regularly
3. **Implement rate limiting** in Edge Function if needed

### Suggested Limits
- **Development**: $20/month limit
- **Production**: Based on user base (estimate 1000 tokens per Nova interaction)

---

## **PART 7: Troubleshooting**

### Common Issues

1. **"OpenAI API key not configured"**
   - Check environment variables in Supabase Edge Functions
   - Verify the key starts with `sk-`

2. **CORS errors**
   - Ensure corsHeaders are set correctly in Edge Function
   - Check that the iOS app can reach Supabase

3. **"Service unavailable"**
   - Check Edge Function logs: `supabase functions logs nova-ai-processor`
   - Verify OpenAI account has credits

4. **Offline mode not working**
   - Ensure local database has cached insights
   - Check that NetworkMonitor.shared.isConnected is working

### Debug Commands

```bash
# Check function status
supabase functions list

# View real-time logs
supabase functions logs nova-ai-processor --follow

# Test function locally
supabase functions serve nova-ai-processor
```

---

## **🎉 Completion Checklist**

- [ ] ✅ Supabase project created
- [ ] ✅ Database tables created with proper RLS
- [ ] ✅ OpenAI API key obtained and configured
- [ ] ✅ Edge Function deployed successfully
- [ ] ✅ iOS app updated with Supabase integration
- [ ] ✅ Environment variables configured
- [ ] ✅ Offline mode tested and working
- [ ] ✅ Online mode tested with real LLM responses
- [ ] ✅ Cost controls implemented
- [ ] ✅ Monitoring dashboard setup

**Congratulations! Nova AI is now powered by real LLM intelligence with full offline fallback capability!** 🚀

---

## **Next Steps**

1. **Enhance Context**: Add more building/task context to improve LLM responses
2. **Conversation Memory**: Implement conversation history persistence  
3. **Advanced Features**: Add voice input, image analysis, etc.
4. **Analytics**: Track Nova usage patterns and optimize responses

Need help? Check the troubleshooting section or review the Edge Function logs for detailed error information.
