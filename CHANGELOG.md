## Changelog

### 2025-08-28

- DSNY models: Removed BinLocation enum usage from DSNYCollectionSchedule and AdminOperationalIntelligence. Replaced with String-based locations to simplify Codable and remove enum coupling started in prior drafts.
- Route bridge: Fixed RouteOperationalBridge initializers for WorkerDashboardViewModel.TaskItem and CoreTypes.ContextualTask; aligned fields, urgency/category mappings, and TimeInterval handling.
- Weather services: Made WeatherDataAdapter public (with public errorDescription on WeatherError) and adjusted Published properties to public read-only for ServiceContainer exposure.
- Weather-triggered tasks: Updated WeatherTriggeredTaskManager Combine pipeline and precipitation mapping to match CoreTypes.WeatherCondition; made Codable IDs decodable by removing default literals and adding initializers with default UUIDs.
- Building details: Aligned BuildingDetailView with current RouteSequence/OperationTask types; added sanitation/operations icons; replaced deprecated accentColor usage; restored glass card modifier via new View+GlassCard.
- Worker profile: Resolved local/global WorkerProfileViewModel conflict by renaming the view-only class; added Equatable/Hashable for BuildingAssignment via extensions.
- Routes: Added WorkerRoute, Kevin/Edwin weekly routes, OperationalCalendar, and RouteManager; integrated routes into ServiceContainer.
- Weather UI: Added WeatherSnapshot model, WeatherScoreBuilder (ScoredTask/TaskRowVM), WeatherRibbonView, and UpcomingTaskListView.
- Housekeeping: Removed deprecated scripts and one-off production helpers; ensured project compiles cleanly with new modules added to the target.

