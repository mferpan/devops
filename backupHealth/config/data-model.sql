DROP TABLE IF EXISTS `clients`;
CREATE TABLE `clients`
(
    `client_id` INTEGER  NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50),
    `Cliente` VARCHAR(50),
    `backup_type_id` INTEGER(1),
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`client_id`),
    INDEX `client_FK` (`client_id`)
)ENGINE=InnoDB;

INSERT INTO clients (name,Cliente,backup_type_id,created_at) VALUES ('CLIENTE1','Cliente',1,NOW());


/* ----------------------------
MF - Monday to Friday
MS - Monday to Sunday (All days)
*/
DROP TABLE IF EXISTS `backup_type`;
CREATE TABLE `backup_type`
(
    `type_id` INTEGER  NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(255),
    PRIMARY KEY (`type_id`),
    INDEX `backup_type_FK` (`type_id`)
)ENGINE=InnoDB;

INSERT INTO backup_type (type) VALUES ('MS');
INSERT INTO backup_type (type) VALUES ('MF');


/* ----------------------------
0 - OK
1 - Warning
2 - Error
3 - Missing
*/
DROP TABLE IF EXISTS `backup_report`;
CREATE TABLE `backup_report` (
    `report_id` INTEGER NOT NULL AUTO_INCREMENT,
    `client_id` INTEGER,
    `report_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `status` INT(1),
    PRIMARY KEY `report_month_idx` (`report_id`,`report_date`),
    KEY `report_client_idx` (`client_id`)
) ENGINE=InnoDB
PARTITION BY RANGE (MONTH(report_date))
(
PARTITION january VALUES LESS THAN (2),
PARTITION february VALUES LESS THAN (3),
PARTITION march VALUES LESS THAN (4),
PARTITION april VALUES LESS THAN (5),
PARTITION may VALUES LESS THAN (6),
PARTITION june VALUES LESS THAN (7),
PARTITION july VALUES LESS THAN (8),
PARTITION august VALUES LESS THAN(9),
PARTITION september VALUES LESS THAN (10),
PARTITION october VALUES LESS THAN (11),
PARTITION november VALUES LESS THAN (12),
PARTITION december VALUES LESS THAN (13)
);

INSERT INTO backup_report (client_id,report_date,status) VALUES (1,NOW(),0);
