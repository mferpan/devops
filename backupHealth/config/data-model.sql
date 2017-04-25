-- DROP TABLE IF EXISTS `clients`;
CREATE TABLE `clients`
(
    `client_id` INTEGER  NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50),
    `backup_type_id` INTEGER(1),
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`client_id`),
    INDEX `blog_comment_FI_1` (`client_id`)
)ENGINE=InnoDB;

-- Client example
-- INSERT INTO clients (name,backup_type_id,created_at) VALUES ('CLIENTE1',1,NOW());



-- DROP TABLE IF EXISTS `backup_type`;
CREATE TABLE `backup_type`
(
    `type_id` INTEGER  NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(255),
    PRIMARY KEY (`type_id`)
)ENGINE=InnoDB;

INSERT INTO backup_type (type) VALUES ('ms');
INSERT INTO backup_type (type) VALUES ('mf');




-- DROP TABLE IF EXISTS `backup_report`;
CREATE TABLE `backup_report` (
    `report_id` INTEGER  NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(255),
    `client_name` VARCHAR(50),
    `report_month` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `type` VARCHAR(255),
    PRIMARY KEY `report_month_idx` (`report_id`,`report_month`),
    KEY `report_client_idx` (`client_name`)
) ENGINE=InnoDB
PARTITION BY LIST (report_month)
(
PARTITION january VALUES IN (1),
PARTITION february VALUES IN (2),
PARTITION march VALUES IN (3),
PARTITION april VALUES IN (4),
PARTITION may VALUES IN (5),
PARTITION june VALUES IN (6),
PARTITION july VALUES IN (7),
PARTITION august VALUES IN (8),
PARTITION september VALUES IN (9),
PARTITION october VALUES IN (10),
PARTITION november VALUES IN (11),
PARTITION december VALUES IN (12)
);

INSERT INTO clients (name,backup_type_id,created_at) VALUES ('CLIENTE1',1,NOW());