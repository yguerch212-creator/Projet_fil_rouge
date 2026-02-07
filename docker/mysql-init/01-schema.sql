USE gmod_construction;

CREATE TABLE IF NOT EXISTS blueprints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_steamid VARCHAR(64) NOT NULL,
    player_name VARCHAR(128) NOT NULL,
    blueprint_name VARCHAR(128) NOT NULL,
    blueprint_data TEXT NOT NULL,
    prop_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_steamid (player_steamid),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steamid VARCHAR(64) NOT NULL,
    permission_level ENUM('user', 'vip', 'admin') DEFAULT 'user',
    max_blueprints INT DEFAULT 5,
    max_props_per_blueprint INT DEFAULT 50,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_steamid (steamid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS blueprint_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steamid VARCHAR(64) NOT NULL,
    action ENUM('save', 'load', 'delete') NOT NULL,
    blueprint_id INT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_steamid (steamid),
    INDEX idx_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO permissions (steamid, permission_level, max_blueprints, max_props_per_blueprint)
VALUES ('STEAM_0:0:00000000', 'admin', 100, 200);

INSERT INTO blueprints (player_steamid, player_name, blueprint_name, blueprint_data, prop_count)
VALUES ('STEAM_0:0:00000000', 'TestUser', 'Test Blueprint', '{"props":[{"model":"models/props_c17/oildrum001.mdl","pos":[0,0,0],"ang":[0,0,0],"frozen":true}]}', 1);
