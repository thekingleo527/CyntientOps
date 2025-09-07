-- Migration script to update Rubin Museum identifier

-- Update building id if it previously used 15 or 18
UPDATE buildings SET id = '14'
WHERE name LIKE 'Rubin Museum%' AND id != '14';

-- Update related foreign keys
UPDATE routine_schedules SET building_id = '14'
WHERE building_id IN ('15','18');

UPDATE worker_building_assignments SET building_id = '14'
WHERE building_id IN ('15','18');

-- Update generic tasks table if present
UPDATE tasks SET building_id = '14'
WHERE building_id IN ('15','18');
