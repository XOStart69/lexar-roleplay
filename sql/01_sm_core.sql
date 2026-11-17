-- Lexar Roleplay - skema dasar sm_core (rekonstruksi, kompatibel qb-core)
-- Impor SETELAH database dibuat:  CREATE DATABASE lexar CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Tabel resource lain (kendaraan, rumah, hp, dll) menyusul dari analisis sql_queries.txt.
-- Tabel ox_inventory: pakai file resmi ox_inventory/setup/install.sql (jangan dibuat ulang di sini).

CREATE TABLE IF NOT EXISTS `players` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `citizenid`    VARCHAR(50)  NOT NULL,
  `cid`          INT(11)      DEFAULT NULL,
  `license`      VARCHAR(255) NOT NULL,           -- isi = identifier QBConfig.LicenseType (default 'steam')
  `name`         VARCHAR(255) NOT NULL,
  `money`        TEXT         NOT NULL,           -- JSON {cash,bank,crypto}
  `charinfo`     LONGTEXT     DEFAULT NULL,       -- JSON; di-query lewat JSON_EXTRACT (phone, account)
  `job`          TEXT         NOT NULL,           -- JSON
  `gang`         TEXT         DEFAULT NULL,       -- JSON
  `position`     TEXT         NOT NULL,           -- JSON {x,y,z,w}
  `metadata`     LONGTEXT     NOT NULL,           -- JSON; di-query lewat JSON_EXTRACT (fingerprint, walletid, phonedata)
  `inventory`    LONGTEXT     DEFAULT NULL,       -- dikelola ox_inventory, core tidak menyentuhnya
  `last_updated` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizenid`),
  KEY `id` (`id`),
  KEY `last_updated` (`last_updated`),
  KEY `license` (`license`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bans` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `name`     VARCHAR(50)  DEFAULT NULL,
  `license`  VARCHAR(255) DEFAULT NULL,
  `discord`  VARCHAR(50)  DEFAULT NULL,
  `ip`       VARCHAR(50)  DEFAULT NULL,
  `reason`   TEXT         DEFAULT NULL,
  `expire`   INT(11)      DEFAULT NULL,           -- unix time; >= 2147483647 = permanen
  `bannedby` VARCHAR(255) NOT NULL DEFAULT 'System',
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
