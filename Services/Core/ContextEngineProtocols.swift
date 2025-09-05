//
//  ContextEngineProtocols.swift
//  CyntientOps
//
//  Context Engine Protocols for breaking circular dependencies
//

import Foundation

// MARK: - Context Engine Protocols

public protocol AdminContextEngineProtocol: AnyObject {
    func setNovaManager(_ nova: NovaAIManager)
}

public protocol WorkerContextEngineProtocol: AnyObject {
    func setNovaManager(_ nova: NovaAIManager)
}

public protocol ClientContextEngineProtocol: AnyObject {
    func setNovaManager(_ nova: NovaAIManager)
}