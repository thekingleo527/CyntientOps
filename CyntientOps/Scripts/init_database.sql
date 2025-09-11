-- CyntientOps Database Initialization Script
-- Run this script to manually initialize the database tables and seed data

-- Create workers table
CREATE TABLE IF NOT EXISTS workers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT DEFAULT 'password',
    role TEXT NOT NULL DEFAULT 'worker',
    phone TEXT,
    hourlyRate REAL DEFAULT 25.0,
    skills TEXT,
    isActive INTEGER NOT NULL DEFAULT 1,
    profileImagePath TEXT,
    address TEXT,
    emergencyContact TEXT,
    notes TEXT,
    shift TEXT,
    lastLogin TEXT,
    loginAttempts INTEGER DEFAULT 0,
    lockedUntil TEXT,
    display_name TEXT,
    timezone TEXT DEFAULT 'America/New_York',
    notification_preferences TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Create buildings table
CREATE TABLE IF NOT EXISTS buildings (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    imageAssetName TEXT,
    numberOfUnits INTEGER,
    propertyManager TEXT,
    emergencyContact TEXT,
    accessInstructions TEXT,
    notes TEXT,
    isActive INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Create clients table
CREATE TABLE IF NOT EXISTS clients (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    short_name TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    address TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Create client_buildings table
CREATE TABLE IF NOT EXISTS client_buildings (
    client_id TEXT NOT NULL,
    building_id TEXT NOT NULL,
    is_primary INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    PRIMARY KEY (client_id, building_id),
    FOREIGN KEY (client_id) REFERENCES clients(id),
    FOREIGN KEY (building_id) REFERENCES buildings(id)
);

-- Create client_users table
CREATE TABLE IF NOT EXISTS client_users (
    user_id TEXT NOT NULL,
    client_id TEXT NOT NULL,
    role TEXT DEFAULT 'viewer',
    can_view_financials INTEGER DEFAULT 0,
    can_edit_settings INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    PRIMARY KEY (user_id, client_id),
    FOREIGN KEY (user_id) REFERENCES workers(id),
    FOREIGN KEY (client_id) REFERENCES clients(id)
);

-- Insert workers
INSERT OR REPLACE INTO workers (id, name, email, password, role, isActive, created_at, updated_at) VALUES
('1', 'Greg Hutson', 'greg.hutson@cyntientops.com', 'GregWorker2025!', 'worker', 1, datetime('now'), datetime('now')),
('2', 'Edwin Lema', 'edwin.lema@cyntientops.com', 'EdwinPark2025!', 'worker', 1, datetime('now'), datetime('now')),
('4', 'Kevin Dutan', 'kevin.dutan@cyntientops.com', 'KevinRubin2025!', 'worker', 1, datetime('now'), datetime('now')),
('5', 'Mercedes Inamagua', 'mercedes.inamagua@cyntientops.com', 'MercedesGlass2025!', 'worker', 1, datetime('now'), datetime('now')),
('6', 'Luis Lopez', 'luis.lopez@cyntientops.com', 'LuisElizabeth2025!', 'worker', 1, datetime('now'), datetime('now')),
('7', 'Angel Guiracocha', 'angel.guiracocha@cyntientops.com', 'AngelBuilding2025!', 'worker', 1, datetime('now'), datetime('now')),
('8', 'Shawn Magloire', 'shawn.magloire@cyntientops.com', 'ShawnHVAC2025!', 'manager', 1, datetime('now'), datetime('now')),
('101', 'David Edelman', 'David@jmrealty.org', 'DavidClient2025!', 'client', 1, datetime('now'), datetime('now'));

-- Insert buildings  
INSERT OR REPLACE INTO buildings (id, name, address, latitude, longitude, imageAssetName) VALUES
('1', '12 West 18th Street', '12 West 18th Street, New York, NY 10011', 40.7387, -73.9941, 'building_12w18'),
('3', '135-139 West 17th Street', '135-139 West 17th Street, New York, NY 10011', 40.7406, -73.9974, 'building_135w17'),
('4', '104 Franklin Street', '104 Franklin Street, New York, NY 10013', 40.7197, -74.0079, 'building_104franklin'),
('5', '138 West 17th Street', '138 West 17th Street, New York, NY 10011', 40.7407, -73.9976, 'building_138w17'),
('6', '68 Perry Street', '68 Perry Street, New York, NY 10014', 40.7351, -74.0063, 'building_68perry'),
('7', '112 West 18th Street', '112 West 18th Street, New York, NY 10011', 40.7388, -73.9957, 'building_112w18'),
('8', '41 Elizabeth Street', '41 Elizabeth Street, New York, NY 10013', 40.7204, -73.9956, 'building_41elizabeth'),
('9', '117 West 17th Street', '117 West 17th Street, New York, NY 10011', 40.7407, -73.9967, 'building_117w17'),
('10', '131 Perry Street', '131 Perry Street, New York, NY 10014', 40.7350, -74.0081, 'building_131perry'),
('11', '123 1st Avenue', '123 1st Avenue, New York, NY 10003', 40.7304, -73.9867, 'building_123first'),
('13', '136 West 17th Street', '136 West 17th Street, New York, NY 10011', 40.7407, -73.9975, 'building_136w17'),
('14', 'Rubin Museum (142–148 W 17th)', '142–148 West 17th Street, New York, NY 10011', 40.7408, -73.9978, 'rubin_museum'),
('15', '133 East 15th Street', '133 East 15th Street, New York, NY 10003', 40.7340, -73.9862, 'building_133e15'),
('16', 'Stuyvesant Cove Park', 'E 18th Street & East River, New York, NY 10009', 40.7281, -73.9738, 'stuyvesant_park'),
('17', '178 Spring Street', '178 Spring Street, New York, NY 10012', 40.7248, -73.9971, ''),
('18', '36 Walker Street', '36 Walker Street, New York, NY 10013', 40.7186, -74.0048, 'building_36walker'),
('19', '115 7th Avenue', '115 7th Avenue, New York, NY 10011', 40.7405, -73.9987, ''),
('20', 'CyntientOps HQ', 'Manhattan, NY', 40.7831, -73.9712, ''),
('21', '148 Chambers Street', '148 Chambers Street, New York, NY 10007', 40.7155, -74.0086, 'building_148chambers');

-- Insert clients
INSERT OR REPLACE INTO clients (id, name, short_name, contact_email, contact_phone, address, is_active, created_at, updated_at) VALUES
('JMR', 'JM Realty', 'JMR', 'David@jmrealty.org', '+1 (212) 555-0200', '350 Fifth Avenue, New York, NY 10118', 1, datetime('now'), datetime('now')),
('WFR', 'Weber Farhat Realty', 'WFR', 'mfarhat@farhatrealtymanagement.com', '+1 (212) 555-0201', '136 West 17th Street, New York, NY 10011', 1, datetime('now'), datetime('now')),
('SOL', 'Solar One', 'SOL', 'facilities@solarone.org', '+1 (212) 555-0202', 'E 18th Street & East River, New York, NY 10009', 1, datetime('now'), datetime('now')),
('GEL', 'Grand Elizabeth LLC', 'GEL', 'management@grandelizabeth.com', '+1 (212) 555-0203', '41 Elizabeth Street, New York, NY 10013', 1, datetime('now'), datetime('now')),
('CIT', 'Citadel Realty', 'CIT', 'property@citadelrealty.com', '+1 (212) 555-0204', '104 Franklin Street, New York, NY 10013', 1, datetime('now'), datetime('now')),
('COR', 'Corbel Property', 'COR', 'admin@corbelproperty.com', '+1 (212) 555-0205', '133 East 15th Street, New York, NY 10003', 1, datetime('now'), datetime('now'));

-- Insert client-building relationships
INSERT OR REPLACE INTO client_buildings (client_id, building_id, is_primary, created_at) VALUES
-- JM Realty (David & Jerry Edelman)
('JMR', '6', 1, datetime('now')),  -- 68 Perry St
('JMR', '10', 0, datetime('now')), -- 131 Perry St
('JMR', '17', 0, datetime('now')), -- 178 Spring St
('JMR', '21', 0, datetime('now')), -- 148 Chambers St
('JMR', '14', 0, datetime('now')), -- Rubin Museum (142–148 W 17th)
('JMR', '5', 0, datetime('now')),  -- 138 W 17th St
('JMR', '3', 0, datetime('now')),  -- 135-139 W 17th St
('JMR', '7', 0, datetime('now')),  -- 112 W 18th St
('JMR', '9', 0, datetime('now')),  -- 117 W 17th St
('JMR', '1', 0, datetime('now')),  -- 12 W 18th St

-- Weber Farhat Realty (Moises Farhat)
('WFR', '13', 1, datetime('now')), -- 136 West 17th Street

-- Solar One (Candace)
('SOL', '16', 1, datetime('now')), -- Stuyvesant Cove Park

-- Citadel Realty (Stephen Shapiro)
('CIT', '4', 1, datetime('now')),  -- 104 Franklin Street
('CIT', '18', 0, datetime('now')), -- 36 Walker Street

-- Corbel Property (Paul Lamban)
('COR', '15', 1, datetime('now')); -- 133 East 15th Street

-- Insert client user associations (THIS IS THE KEY FIX)
INSERT OR REPLACE INTO client_users (user_id, client_id, role, can_view_financials, can_edit_settings, created_at) VALUES
('101', 'JMR', 'client', 1, 1, datetime('now')),  -- David Edelman -> JM Realty
('102', 'JMR', 'client', 1, 1, datetime('now'));  -- Jerry Edelman -> JM Realty

-- Create additional necessary tables
CREATE TABLE IF NOT EXISTS routine_tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    buildingId TEXT,
    workerId TEXT,
    scheduledDate TEXT,
    dueDate TEXT,
    completedDate TEXT,
    isCompleted INTEGER DEFAULT 0,
    category TEXT,
    urgency TEXT,
    requiresPhoto INTEGER DEFAULT 0,
    photoPath TEXT,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (buildingId) REFERENCES buildings(id),
    FOREIGN KEY (workerId) REFERENCES workers(id)
);

CREATE TABLE IF NOT EXISTS worker_building_assignments (
    id TEXT PRIMARY KEY,
    worker_id TEXT NOT NULL,
    building_id TEXT NOT NULL,
    role TEXT NOT NULL,
    assigned_date TEXT DEFAULT CURRENT_TIMESTAMP,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (worker_id) REFERENCES workers(id),
    FOREIGN KEY (building_id) REFERENCES buildings(id),
    UNIQUE(worker_id, building_id, role)
);