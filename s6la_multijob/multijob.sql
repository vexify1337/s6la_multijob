CREATE TABLE IF NOT EXISTS `s6la_multijob` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `job_name` varchar(50) NOT NULL,
  `job_label` varchar(100) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `grade_label` varchar(100) DEFAULT NULL,
  `salary` int(11) NOT NULL DEFAULT 0,
  `added_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_job` (`identifier`, `job_name`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
