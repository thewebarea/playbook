CREATE TABLE IF NOT EXISTS `users` (
  `Login` varchar(255) NOT NULL,
  `Password` varchar(32) NOT NULL,
  `Dir` varchar(255) NOT NULL DEFAULT '/var/www/',
  PRIMARY KEY (`Login`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
