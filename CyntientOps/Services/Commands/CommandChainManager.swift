//
//  CommandChainManager.swift
//  CyntientOps Phase 6
//
//  Command Chain Manager for resilient multi-step operations
//  All critical operations are executed through command chains for reliability
//

import Foundation
import Combine

@MainActor
public final class CommandChainManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var activeChains: [String: CommandChain] = [:]
    @Published public var chainHistory: [ChainExecution] = []
    @Published public var failedChains: [String] = []
    @Published public var successfulChains: Int = 0
    @Published public var isProcessing: Bool = false
    
    // MARK: - Dependencies
    private let container: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private struct Config {
        static let maxRetryAttempts = 3
        static let retryDelayMultiplier = 2.0
        static let chainTimeout: TimeInterval = 60.0
        static let maxConcurrentChains = 10
    }
    
    public init(container: ServiceContainer) {
        self.container = container
        setupChainMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Execute a task completion chain
    public func executeTaskCompletion(
        taskId: String,
        workerId: String,
        photoData: Data? = nil,
        notes: String? = nil
    ) async throws -> CommandChainResult {
        
        let chainId = "task_completion_\(taskId)_\(UUID().uuidString.prefix(8))"
        
        let steps: [CommandStep] = [
            ValidateTaskCommand(taskId: taskId, workerId: workerId, container: container),
            CheckPhotoRequirementCommand(taskId: taskId, photoData: photoData, container: container),
            DatabaseTransactionCommand(taskId: taskId, workerId: workerId, notes: notes, container: container),
            RealTimeSyncCommand(taskId: taskId, container: container),
            IntelligenceUpdateCommand(taskId: taskId, workerId: workerId, container: container)
        ]
        
        let chain = CommandChain(
            id: chainId,
            name: "Task Completion",
            steps: steps,
            timeout: Config.chainTimeout
        )
        
        return try await executeChain(chain)
    }
    
    /// Execute a clock-in chain
    public func executeClockIn(
        workerId: String,
        buildingId: String,
        latitude: Double,
        longitude: Double
    ) async throws -> CommandChainResult {
        
        let chainId = "clock_in_\(workerId)_\(UUID().uuidString.prefix(8))"
        
        let steps: [CommandStep] = [
            ValidateLocationCommand(buildingId: buildingId, latitude: latitude, longitude: longitude, container: container),
            CheckBuildingAccessCommand(workerId: workerId, buildingId: buildingId, container: container),
            CreateClockInRecordCommand(workerId: workerId, buildingId: buildingId, latitude: latitude, longitude: longitude, container: container),
            LoadWorkerTasksCommand(workerId: workerId, buildingId: buildingId, container: container),
            UpdateDashboardsCommand(workerId: workerId, action: .clockIn, container: container)
        ]
        
        let chain = CommandChain(
            id: chainId,
            name: "Clock In",
            steps: steps,
            timeout: Config.chainTimeout
        )
        
        return try await executeChain(chain)
    }
    
    /// Execute a photo capture chain
    public func executePhotoCapture(
        taskId: String,
        imageData: Data,
        workerId: String
    ) async throws -> CommandChainResult {
        
        let chainId = "photo_capture_\(taskId)_\(UUID().uuidString.prefix(8))"
        
        let steps: [CommandStep] = [
            CaptureImageCommand(imageData: imageData, taskId: taskId),
            EncryptImageCommand(imageData: imageData, ttlHours: 72), // 72-hour TTL
            GenerateThumbnailCommand(imageData: imageData),
            UploadToStorageCommand(taskId: taskId, workerId: workerId, container: container),
            LinkToTaskCommand(taskId: taskId, container: container)
        ]
        
        let chain = CommandChain(
            id: chainId,
            name: "Photo Capture",
            steps: steps,
            timeout: Config.chainTimeout
        )
        
        return try await executeChain(chain)
    }
    
    /// Execute a compliance resolution chain (NEW)
    public func executeComplianceResolution(
        violationId: String,
        buildingId: String,
        workerId: String? = nil
    ) async throws -> CommandChainResult {
        
        let chainId = "compliance_resolution_\(violationId)_\(UUID().uuidString.prefix(8))"
        
        let steps: [CommandStep] = [
            FetchViolationCommand(violationId: violationId, buildingId: buildingId, container: container),
            CreateResolutionTaskCommand(violationId: violationId, buildingId: buildingId, container: container),
            AssignToWorkerCommand(buildingId: buildingId, workerId: workerId, container: container),
            SetDeadlineCommand(violationId: violationId, container: container),
            MonitorProgressCommand(violationId: violationId, container: container)
        ]
        
        let chain = CommandChain(
            id: chainId,
            name: "Compliance Resolution",
            steps: steps,
            timeout: Config.chainTimeout * 2 // Longer timeout for compliance
        )
        
        return try await executeChain(chain)
    }
    
    /// Get chain execution history
    public func getChainHistory(limit: Int = 50) -> [ChainExecution] {
        return Array(chainHistory.sorted { $0.startTime > $1.startTime }.prefix(limit))
    }
    
    /// Get active chain status
    public func getActiveChains() -> [CommandChain] {
        return Array(activeChains.values)
    }
    
    /// Cancel a running chain
    public func cancelChain(_ chainId: String) {
        if let chain = activeChains[chainId] {
            chain.cancel()
            activeChains.removeValue(forKey: chainId)
            
            // Record cancellation
            let execution = ChainExecution(
                chainId: chainId,
                chainName: chain.name,
                startTime: Date(),
                endTime: Date(),
                status: .cancelled,
                steps: [],
                error: nil
            )
            chainHistory.append(execution)
        }
    }
    
    // MARK: - Private Methods
    
    private func executeChain(_ chain: CommandChain) async throws -> CommandChainResult {
        let startTime = Date()
        activeChains[chain.id] = chain
        
        var executedSteps: [StepExecution] = []
        var currentStep = 0
        
        do {
            // Create timeout task
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(chain.timeout * 1_000_000_000))
                throw CommandChainError.timeout
            }
            
            // Execute steps with timeout
            let executionTask = Task {
                for step in chain.steps {
                    if Task.isCancelled { break }
                    
                    let stepStartTime = Date()
                    
                    do {
                        let result = try await executeStepWithRetry(step)
                        
                        let stepExecution = StepExecution(
                            stepName: step.name,
                            startTime: stepStartTime,
                            endTime: Date(),
                            status: .success,
                            result: result,
                            error: nil,
                            retryCount: 0
                        )
                        
                        executedSteps.append(stepExecution)
                        currentStep += 1
                        
                    } catch {
                        let stepExecution = StepExecution(
                            stepName: step.name,
                            startTime: stepStartTime,
                            endTime: Date(),
                            status: .failed,
                            result: nil,
                            error: error.localizedDescription,
                            retryCount: 0
                        )
                        
                        executedSteps.append(stepExecution)
                        throw error
                    }
                }
            }
            
            // Race between execution and timeout
            _ = try await Task.raceWithTimeout(executionTask, timeoutTask)
            timeoutTask.cancel()
            
            // Success
            activeChains.removeValue(forKey: chain.id)
            successfulChains += 1
            isProcessing = false
            
            let execution = ChainExecution(
                chainId: chain.id,
                chainName: chain.name,
                startTime: startTime,
                endTime: Date(),
                status: .success,
                steps: executedSteps,
                error: nil
            )
            
            chainHistory.append(execution)
            
            return CommandChainResult(
                chainId: chain.id,
                success: true,
                steps: executedSteps,
                error: nil,
                duration: Date().timeIntervalSince(startTime)
            )
            
        } catch {
            // Failure
            activeChains.removeValue(forKey: chain.id)
            failedChains.append(chain.id)
            isProcessing = false
            
            let execution = ChainExecution(
                chainId: chain.id,
                chainName: chain.name,
                startTime: startTime,
                endTime: Date(),
                status: .failed,
                steps: executedSteps,
                error: error.localizedDescription
            )
            
            chainHistory.append(execution)
            
            return CommandChainResult(
                chainId: chain.id,
                success: false,
                steps: executedSteps,
                error: error.localizedDescription,
                duration: Date().timeIntervalSince(startTime)
            )
        }
    }
    
    private func executeStepWithRetry(_ step: CommandStep, attempt: Int = 1) async throws -> Any? {
        do {
            return try await step.execute()
        } catch {
            if attempt < Config.maxRetryAttempts && step.isRetryable {
                let delay = Config.retryDelayMultiplier * Double(attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeStepWithRetry(step, attempt: attempt + 1)
            } else {
                throw error
            }
        }
    }
    
    private func setupChainMonitoring() {
        // Monitor chain completions for analytics
        $chainHistory
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] history in
                self?.analyzeChainPerformance(history)
            }
            .store(in: &cancellables)
    }
    
    private func analyzeChainPerformance(_ history: [ChainExecution]) {
        let recentExecutions = history.suffix(20)
        let successRate = Double(recentExecutions.filter { $0.status == .success }.count) / Double(recentExecutions.count)
        
        if successRate < 0.8 {
            print("⚠️ Command chain success rate low: \(String(format: "%.1f", successRate * 100))%")
        }
        
        // Report to Nova AI for insights
        container.intelligence.reportChainMetrics(successRate: successRate, recentExecutions: recentExecutions.count)
    }
}

// MARK: - Supporting Types

public class CommandChain {
    public let id: String
    public let name: String
    public let steps: [CommandStep]
    public let timeout: TimeInterval
    
    private var isCancelled = false
    
    public init(id: String, name: String, steps: [CommandStep], timeout: TimeInterval) {
        self.id = id
        self.name = name
        self.steps = steps
        self.timeout = timeout
    }
    
    public func cancel() {
        isCancelled = true
    }
    
    public var cancelled: Bool {
        return isCancelled
    }
}

public protocol CommandStep {
    var name: String { get }
    var isRetryable: Bool { get }
    func execute() async throws -> Any?
}

public struct CommandChainResult {
    public let chainId: String
    public let success: Bool
    public let steps: [StepExecution]
    public let error: String?
    public let duration: TimeInterval
}

public struct ChainExecution {
    public let chainId: String
    public let chainName: String
    public let startTime: Date
    public let endTime: Date
    public let status: ExecutionStatus
    public let steps: [StepExecution]
    public let error: String?
    
    public enum ExecutionStatus {
        case success, failed, cancelled, timeout
    }
}

public struct StepExecution {
    public let stepName: String
    public let startTime: Date
    public let endTime: Date
    public let status: StepStatus
    public let result: Any?
    public let error: String?
    public let retryCount: Int
    
    public enum StepStatus {
        case success, failed, skipped
    }
}

public enum CommandChainError: LocalizedError {
    case timeout
    case stepFailed(String)
    case chainCancelled
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Command chain timed out"
        case .stepFailed(let step):
            return "Step failed: \(step)"
        case .chainCancelled:
            return "Command chain was cancelled"
        case .invalidConfiguration:
            return "Invalid chain configuration"
        }
    }
}

// MARK: - Task Extension for Timeout Racing

extension Task where Success == Void, Failure == Error {
    static func raceWithTimeout<T>(_ operation: Task<T, Error>, _ timeout: Task<Void, Error>) async throws -> T {
        return try await withThrowingTaskGroup(of: TaskRaceResult<T>.self) { group in
            group.addTask {
                let result = try await operation.value
                return .success(result)
            }
            
            group.addTask {
                try await timeout.value
                return .timeout
            }
            
            guard let first = try await group.next() else {
                throw CommandChainError.timeout
            }
            
            group.cancelAll()
            
            switch first {
            case .success(let value):
                return value
            case .timeout:
                throw CommandChainError.timeout
            }
        }
    }
}

private enum TaskRaceResult<T> {
    case success(T)
    case timeout
}