-- Skema DB. Dijalankan sekali saat boot oleh escrow/server/main.lua.
local T = Config.Server.tables

return {
    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.homes) .. [[
        `identifier` VARCHAR(64) NOT NULL PRIMARY KEY,
        `name` VARCHAR(120) NOT NULL DEFAULT '',
        `price` INT NOT NULL DEFAULT 0,
        `payment` INT NOT NULL DEFAULT 0,
        `type` VARCHAR(20) NOT NULL DEFAULT 'shell',
        `complex` VARCHAR(20) NOT NULL DEFAULT 'Individual',
        `owner` VARCHAR(64) NULL,
        `realestate` VARCHAR(64) NULL,
        `entry` TEXT NULL,
        `area` TEXT NULL,
        `data` TEXT NULL,
        `configuration` TEXT NULL,
        `permission` TEXT NULL,
        `thumbnail` TEXT NULL,
        `interior` VARCHAR(120) NULL,
        `placement` TEXT NULL,
        `disabled` TINYINT(1) NOT NULL DEFAULT 0,
        `locked` TINYINT(1) NOT NULL DEFAULT 0,
        `created_at` INT NOT NULL DEFAULT 0,
        `bought_at` INT NOT NULL DEFAULT 0,
        `lastLogin` INT NOT NULL DEFAULT 0,
        `realestateFee` INT NOT NULL DEFAULT 0,
        INDEX `idx_owner` (`owner`),
        INDEX `idx_realestate` (`realestate`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.doors) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `name` VARCHAR(80) NOT NULL,
        `coords` TEXT NOT NULL,
        `model` VARCHAR(80) NULL,
        `state` TINYINT(1) NOT NULL DEFAULT 0,
        INDEX `idx_home` (`home`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.garages) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `name` VARCHAR(80) NOT NULL,
        `coords` TEXT NOT NULL,
        `type` TEXT NULL,
        INDEX `idx_home` (`home`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.teleports) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `name` VARCHAR(80) NOT NULL,
        `inside` TEXT NOT NULL,
        `outside` TEXT NOT NULL,
        `locked` TINYINT(1) NOT NULL DEFAULT 0,
        INDEX `idx_home` (`home`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.storages) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `aptId` INT NULL,
        `storageId` VARCHAR(40) NOT NULL,
        `coords` TEXT NULL,
        `area` VARCHAR(40) NULL,
        `weight` INT NOT NULL DEFAULT 100000,
        `slots` INT NOT NULL DEFAULT 10,
        `type` VARCHAR(20) NOT NULL DEFAULT 'zone',
        INDEX `idx_home` (`home`, `aptId`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.wardrobes) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `aptId` INT NULL,
        `name` VARCHAR(80) NOT NULL,
        `coords` TEXT NOT NULL,
        `outfits` TEXT NULL,
        INDEX `idx_home` (`home`, `aptId`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.furniture) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `aptId` INT NULL,
        `model` VARCHAR(100) NOT NULL,
        `label` VARCHAR(120) NULL,
        `coords` TEXT NOT NULL,
        `rotation` TEXT NULL,
        `heading` FLOAT NOT NULL DEFAULT 0,
        `area` VARCHAR(40) NULL,
        `identifier` VARCHAR(40) NULL,
        INDEX `idx_home` (`home`, `aptId`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.keys) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `aptId` INT NULL,
        `holder` VARCHAR(64) NULL,
        `name` VARCHAR(80) NOT NULL,
        `permissions` TEXT NULL,
        `isList` TINYINT(1) NOT NULL DEFAULT 0,
        INDEX `idx_home` (`home`, `aptId`),
        INDEX `idx_holder` (`holder`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.apartments) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `owner` VARCHAR(64) NULL,
        `name` VARCHAR(80) NOT NULL,
        `price` INT NOT NULL DEFAULT 0,
        `locked` TINYINT(1) NOT NULL DEFAULT 0,
        `storages` TEXT NULL,
        `wardrobes` TEXT NULL,
        `furniture` TEXT NULL,
        INDEX `idx_home` (`home`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.mortgages) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `aptId` INT NULL,
        `owner` VARCHAR(64) NOT NULL,
        `downpayment` INT NOT NULL DEFAULT 0,
        `interest` FLOAT NOT NULL DEFAULT 0,
        `duration` INT NOT NULL DEFAULT 0,
        `payment` INT NOT NULL DEFAULT 0,
        `lastPayment` INT NOT NULL DEFAULT 0,
        `remaining` INT NOT NULL DEFAULT 0,
        INDEX `idx_home` (`home`, `aptId`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.logs) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NULL,
        `action` VARCHAR(60) NOT NULL,
        `message` TEXT NOT NULL,
        `author` VARCHAR(80) NULL,
        `created_at` INT NOT NULL DEFAULT 0,
        INDEX `idx_home` (`home`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.catalogues) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `interior` VARCHAR(120) NOT NULL,
        `type` VARCHAR(20) NOT NULL,
        `price` INT NOT NULL DEFAULT 0,
        `label` VARCHAR(120) NULL,
        UNIQUE KEY `uniq_interior_type` (`interior`, `type`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.bills) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `home` VARCHAR(64) NOT NULL,
        `aptId` INT NULL,
        `type` VARCHAR(40) NOT NULL,
        `amount` INT NOT NULL DEFAULT 0,
        `paid` TINYINT(1) NOT NULL DEFAULT 0,
        `created_at` INT NOT NULL DEFAULT 0,
        INDEX `idx_home` (`home`, `aptId`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.starter) .. [[
        `home` VARCHAR(64) NOT NULL PRIMARY KEY
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],

    ('CREATE TABLE IF NOT EXISTS `%s` ('):format(T.presets) .. [[
        `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        `name` VARCHAR(80) NOT NULL,
        `points` TEXT NOT NULL,
        `height` FLOAT NOT NULL DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
}