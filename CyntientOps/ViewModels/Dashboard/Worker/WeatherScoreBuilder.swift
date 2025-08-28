//
//  WeatherScoreBuilder.swift
//  CyntientOps
//
//  Weather-aware task scoring and reordering logic
//  Scores tasks based on weather conditions and timing
//

import Foundation

// MARK: - Scored Task Result

public struct ScoredTask {
    public let task: CoreTypes.ContextualTask
    public let chip: WeatherChip?
    public let advice: String?
    public let score: Int
    
    public init(task: CoreTypes.ContextualTask, chip: WeatherChip? = nil, advice: String? = nil, score: Int) {
        self.task = task
        self.chip = chip
        self.advice = advice
        self.score = score
    }
}

// MARK: - Weather Score Builder

public enum WeatherScoreBuilder {
    
    /// Score a task based on weather conditions and timing
    public static func score(task: CoreTypes.ContextualTask, weather: WeatherSnapshot) -> ScoredTask {
        let category = WeatherProfiles.categoryFromString(task.category?.rawValue)
        let profile = WeatherProfiles.forCategory(category)
        
        // Find the hour block nearest to task due time
        let taskTime = task.dueDate ?? Date()
        let block = nearestBlock(to: taskTime, from: weather.hourly)
        
        var penalty = 0
        var chip: WeatherChip? = nil
        var advice: String? = nil
        
        // Weather-based scoring for outdoor tasks
        if profile.isOutdoor, let weatherBlock = block {
            // Precipitation penalty
            if profile.sensitiveToPrecip, let maxPrecip = profile.idealPrecipProbMax {
                if weatherBlock.precipProb >= 0.6 {
                    penalty += 3
                    chip = .heavyRain
                    advice = "Do indoor tasks; rain likely."
                } else if weatherBlock.precipProb >= maxPrecip {
                    penalty += 1
                    chip = .wet
                    advice = "Wet window likely—consider reslotting."
                }
            }
            
            // Wind penalty
            if profile.sensitiveToWind, let maxWind = profile.idealWindMax, weatherBlock.windMph > maxWind {
                penalty += 1
                chip = chip ?? .windy
                advice = advice ?? "High wind; bag/tie securely."
            }
            
            // Temperature comfort
            if weatherBlock.tempF <= 25 {
                penalty += 1
                chip = chip ?? .cold
                advice = advice ?? "Very cold—reduce outdoor exposure."
            } else if weatherBlock.tempF >= 95 {
                penalty += 1
                chip = chip ?? .hot
                advice = advice ?? "Heat—hydrate & pace work."
            }
        }
        
        // Good weather bonus for outdoor tasks
        if chip == nil, profile.isOutdoor, let weatherBlock = block,
           weatherBlock.precipProb < 0.2, weatherBlock.windMph < 20 {
            chip = .goodWindow
            penalty -= 1  // Small bonus for good conditions
        }
        
        // Time-based priority (earlier = lower penalty)
        let basePriority = basePriorityFor(task)
        let finalScore = basePriority + penalty
        
        return ScoredTask(task: task, chip: chip, advice: advice, score: finalScore)
    }
    
    // MARK: - Helper Methods
    
    private static func nearestBlock(to date: Date, from blocks: [WeatherSnapshot.HourBlock]) -> WeatherSnapshot.HourBlock? {
        guard !blocks.isEmpty else { return nil }
        return blocks.min { block1, block2 in
            abs(block1.date.timeIntervalSince(date)) < abs(block2.date.timeIntervalSince(date))
        }
    }
    
    private static func bestDrierWindow(around date: Date, in blocks: [WeatherSnapshot.HourBlock]) -> WeatherSnapshot.HourBlock? {
        // Search ±3 hours for lowest precip probability
        let window = blocks.filter { abs($0.date.timeIntervalSince(date)) <= 3 * 3600 }
        return window.min { $0.precipProb < $1.precipProb }
    }
    
    private static func basePriorityFor(_ task: CoreTypes.ContextualTask) -> Int {
        // Earlier due times get lower scores (higher priority)
        let dueDate = task.dueDate ?? Date.distantFuture
        let minutesFromNow = Calendar.current.dateComponents([.minute], from: Date(), to: dueDate).minute ?? 9999
        
        // Every 30 minutes increments score by 1
        let timeScore = max(0, minutesFromNow / 30)
        
        // Category importance (some categories are inherently higher priority)
        let categoryBonus: Int
        switch task.category {
        case .some(.sanitation): categoryBonus = -2  // DSNY sanitation tasks are critical
        case .some(.maintenance): categoryBonus = -1 // Maintenance is important
        case .some(.cleaning): categoryBonus = 0     // Standard priority
        case .some(.inspection): categoryBonus = 1   // Can be delayed
        default: categoryBonus = 0
        }
        
        return timeScore + categoryBonus
    }
}

// MARK: - Task Row View Model

public struct TaskRowVM: Identifiable {
    public let id = UUID()
    public let title: String
    public let time: String
    public let building: String
    public let chip: WeatherChip?
    public let advice: String?
    
    public init(scored: ScoredTask) {
        self.title = scored.task.title
        self.time = scored.task.dueDate?.formatted(date: .omitted, time: .shortened) ?? "No time"
        self.building = "Building" // TODO: Extract from task context
        self.chip = scored.chip
        self.advice = scored.advice
    }
}
