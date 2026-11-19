CREATE TABLE IF NOT EXISTS `sm_custom_swaps` (
  `plate` varchar(16) NOT NULL,
  `sound` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`plate`)
);

CREATE TABLE IF NOT EXISTS `sm_custom_fitments` (
  `key` varchar(48) NOT NULL,
  `plate` varchar(16) NOT NULL,
  `data` longtext DEFAULT NULL,
  PRIMARY KEY (`key`),
  KEY `plate` (`plate`)
);

CREATE TABLE IF NOT EXISTS `player_vehicles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `license` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `vehicle` varchar(50) DEFAULT NULL,
  `hash` varchar(50) DEFAULT NULL,
  `mods` longtext DEFAULT NULL,
  `plate` varchar(16) NOT NULL,
  `fakeplate` varchar(15) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `fuel` int DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `state` int DEFAULT 1,
  `depotprice` int DEFAULT 0,
  `drivingdistance` int DEFAULT NULL,
  `status` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `sm_custom_nitrous` (
  `plate` varchar(16) NOT NULL,
  `level` int DEFAULT 0,
  PRIMARY KEY (`plate`)
);
