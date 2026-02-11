-- ============================================================================
-- RP Construction System - Schéma SQL
-- Compatible MySQL 5.7+ / MariaDB 10.2+
--
-- Ce schéma est OPTIONNEL. La base de données est utilisée uniquement pour :
--   - Les logs d'activité (audit/administration)
--   - Le futur système de partage de blueprints entre joueurs
--
-- Les sauvegardes de blueprints sont stockées LOCALEMENT sur le client.
--
-- INSTALLATION :
--   1. Créez une base de données : CREATE DATABASE gmod_construction;
--   2. Créez un utilisateur dédié (voir ci-dessous)
--   3. Exécutez ce fichier : mysql -u root -p gmod_construction < schema.sql
--   4. Configurez les identifiants dans lua/rp_construction/sh_config.lua
--
-- Ce script est SAFE à exécuter sur une base existante (IF NOT EXISTS).
-- ============================================================================

-- Utilisateur dédié (adapter le mot de passe !)
-- CREATE USER IF NOT EXISTS 'gmod_construction'@'%' IDENTIFIED BY 'CHANGEZ_MOI';
-- GRANT ALL PRIVILEGES ON gmod_construction.* TO 'gmod_construction'@'%';
-- FLUSH PRIVILEGES;

-- ============================================================================
-- TABLE : blueprint_logs
-- Historique des actions (save, load, delete, share)
-- ============================================================================
CREATE TABLE IF NOT EXISTS `blueprint_logs` (
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `steam_id`    VARCHAR(32)     NOT NULL,
    `player_name` VARCHAR(64)     NOT NULL DEFAULT '',
    `action`      VARCHAR(32)     NOT NULL,
    `details`     TEXT            DEFAULT NULL,
    `ip_address`  VARCHAR(45)     DEFAULT NULL,
    `created_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_steam_id` (`steam_id`),
    INDEX `idx_action` (`action`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE : shared_blueprints (FUTUR - partage entre joueurs)
-- Blueprints partagés sur le serveur (upload volontaire)
-- ============================================================================
CREATE TABLE IF NOT EXISTS `shared_blueprints` (
    `id`               INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `steam_id`         VARCHAR(32)     NOT NULL,
    `player_name`      VARCHAR(64)     NOT NULL DEFAULT '',
    `name`             VARCHAR(64)     NOT NULL,
    `description`      VARCHAR(256)    DEFAULT '',
    `prop_count`       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `data`             MEDIUMBLOB      NOT NULL,
    `is_public`        TINYINT(1)      NOT NULL DEFAULT 0,
    `downloads`        INT UNSIGNED    NOT NULL DEFAULT 0,
    `created_at`       TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_steam_id` (`steam_id`),
    INDEX `idx_public` (`is_public`),
    INDEX `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TABLE : blueprint_permissions (FUTUR - permissions de partage)
-- ============================================================================
CREATE TABLE IF NOT EXISTS `blueprint_permissions` (
    `id`               INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `blueprint_id`     INT UNSIGNED    NOT NULL,
    `target_steam_id`  VARCHAR(32)     NOT NULL,
    `permission_level` ENUM('view', 'use', 'edit') NOT NULL DEFAULT 'view',
    `granted_at`       TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_blueprint_target` (`blueprint_id`, `target_steam_id`),
    INDEX `idx_target` (`target_steam_id`),
    CONSTRAINT `fk_perm_blueprint` FOREIGN KEY (`blueprint_id`)
        REFERENCES `shared_blueprints` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
