-- RP Construction System - Schéma MySQL
-- Ce fichier est exécuté automatiquement au premier démarrage de MySQL

CREATE DATABASE IF NOT EXISTS gmod_construction;
USE gmod_construction;

-- Table des blueprints (constructions sauvegardées)
CREATE TABLE IF NOT EXISTS blueprints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_steamid VARCHAR(32) NOT NULL,
    owner_name VARCHAR(64) NOT NULL,
    name VARCHAR(50) NOT NULL,
    description VARCHAR(200) DEFAULT '',
    data LONGTEXT NOT NULL,
    prop_count INT DEFAULT 0,
    constraint_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_public TINYINT(1) DEFAULT 0,
    INDEX idx_owner (owner_steamid),
    INDEX idx_public (is_public)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des permissions de partage
CREATE TABLE IF NOT EXISTS blueprint_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    blueprint_id INT NOT NULL,
    target_steamid VARCHAR(32) NOT NULL,
    permission_level ENUM('view', 'use', 'edit') DEFAULT 'use',
    granted_by VARCHAR(32) NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (blueprint_id) REFERENCES blueprints(id) ON DELETE CASCADE,
    UNIQUE KEY uk_bp_target (blueprint_id, target_steamid),
    INDEX idx_target (target_steamid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des logs d'actions
CREATE TABLE IF NOT EXISTS blueprint_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    steamid VARCHAR(32) NOT NULL,
    player_name VARCHAR(64) NOT NULL,
    action ENUM('save', 'load', 'delete', 'share', 'unshare', 'update') NOT NULL,
    blueprint_id INT DEFAULT NULL,
    blueprint_name VARCHAR(50) DEFAULT '',
    details TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_steamid (steamid),
    INDEX idx_action (action),
    INDEX idx_date (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
