/*
 *  TABLE CONTAINERS
 */
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id INT(30) NOT NULL AUTO_INCREMENT,
  email VARCHAR(60) NOT NULL,
  password VARCHAR(32) NOT NULL,
  name VARCHAR(25) NOT NULL,
  surname VARCHAR(50) NOT NULL,
  address VARCHAR(80) NOT NULL,
  city VARCHAR(30) NOT NULL,
  province VARCHAR(2) NOT NULL,
  postcode INT(7) NOT NULL,
  country VARCHAR(7) NOT NULL,
  register_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id,email),
  KEY (id)
) ENGINE=InnoDB;

INSERT INTO users (email,password,name,surname,address,city,province,postcode,country) VALUES ("manuel@backendaas.com","04d968d0b9e4b0ca9f6d557a3b3a57f7","manuel","fernandez panzuela","mi casa en dos hermanas","sevilla","andalucia",41700,"España");
INSERT INTO users (email,password,name,surname,address,city,province,postcode,country) VALUES ("javier@backendaas.com","04d968d0b9e4b0ca9f6d557a3b3a57f7","manuel","fernandez panzuela","mi casa en dos hermanas","sevilla","andalucia",41700,"España");


/*
 *  TABLE CONTAINERS
 */
DROP TABLE IF EXISTS containers;
CREATE TABLE containers (
  id INT(30) NOT NULL AUTO_INCREMENT,
  user_id VARCHAR(32) NOT NULL,
  container_type VARCHAR (10),
  expiration_date DATETIME NOT NULL,
  creation_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  mac VARCHAR(18),
  ip_address VARCHAR(15),
  root_password VARCHAR(12),
  PRIMARY KEY (id,user_id),
  KEY (id)
) ENGINE=InnoDB;

INSERT INTO containers (user_id,container_type,expiration_date,creation_date,mac,ip_address,root_password) VALUES ("contenedor00","FREE","2016-01-15 13:22:59",NOW(),"A8-26-66-41-B2-C3","10.10.0.2","7asrya0sd8ah");
INSERT INTO containers (user_id,container_type,expiration_date,creation_date,mac,ip_address,root_password) VALUES ("contenedor01","FREE","2014-01-15 13:22:59",NOW(),"A8-27-33-41-B2-C3","10.10.0.3","7asrya0sd8ah");


/*
 *  TABLE PENDING_CONTAINERS, CONTAINERS PENDING TO BE CREATED
 */
DROP TABLE IF EXISTS pending_containers;
CREATE TABLE pending_containers (
  id INT(30) NOT NULL AUTO_INCREMENT,
  user_id VARCHAR(32) NOT NULL,
  container_type VARCHAR (10),
  template VARCHAR(50),
  expiration_date DATETIME NOT NULL,
  PRIMARY KEY (id,user_id),
  KEY (id)
) ENGINE=InnoDB;

INSERT INTO pending_containers (user_id,container_type,template,expiration_date) VALUES ("container1","FREE","centos","2015-01-15 13:22:59");
INSERT INTO pending_containers (user_id,container_type,template,expiration_date) VALUES ("container2","FREE","centos","2015-01-15 13:22:59");
INSERT INTO pending_containers (user_id,container_type,template,expiration_date) VALUES ("container3","FREE","centos","2015-01-15 13:22:59");


/*
 *  TABLE CONTAINER_DEFINITION, DESCRIBE FOUR CONTAINERS TYPE
 */
DROP TABLE IF EXISTS container_definition;
CREATE TABLE container_definition (
  id INT(30) NOT NULL AUTO_INCREMENT,
  name VARCHAR (10),
  start_at_boot INT(1),
  network_type VARCHAR(10),
  network_link VARCHAR(10),
  memory_limit INT(6),
  memory_swap_limit INT(6),
  num_cpus VARCHAR(5),
  disk_size VARCHAR(10),
  PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO container_definition (name,start_at_boot,network_type,network_link,memory_limit,memory_swap_limit,num_cpus,disk_size) VALUES ("FREE","Y","veth","virbr0","512","768","0-1","10000");
INSERT INTO container_definition (name,start_at_boot,network_type,network_link,memory_limit,memory_swap_limit,num_cpus,disk_size) VALUES ("BRONZE","Y","veth","virbr0","1024","2048","2-3","100000");
INSERT INTO container_definition (name,start_at_boot,network_type,network_link,memory_limit,memory_swap_limit,num_cpus,disk_size) VALUES ("SILVER","Y","veth","virbr0","2048","4096","4-8","200000");
INSERT INTO container_definition (name,start_at_boot,network_type,network_link,memory_limit,memory_swap_limit,num_cpus,disk_size) VALUES ("GOLD","Y","veth","virbr0","4096","8192","9-15","500000");


/*
 *  TABLE IMAGES, are images available to be used
 */
DROP TABLE IF EXISTS images;
CREATE TABLE images (
  id INT(30) NOT NULL AUTO_INCREMENT,
  name VARCHAR (10) NOT NULL,
  arch VARCHAR(6) NOT NULL,
  kernel VARCHAR(20) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO images (name,arch,kernel) VALUES ("Fedora","x86_64","3.17.4-200.fc20.x86_64");

/*
 *  TABLE IPADDRESSES. 4094 adresses available
 */
DROP TABLE IF EXISTS lxc_templates;
CREATE TABLE lxc_templates (
  id INT(30) NOT NULL AUTO_INCREMENT,
  name VARCHAR (15) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO lxc_templates (name) VALUES ("alpine");
INSERT INTO lxc_templates (name) VALUES ("altlinux");
INSERT INTO lxc_templates (name) VALUES ("archlinux");
INSERT INTO lxc_templates (name) VALUES ("busybox");
INSERT INTO lxc_templates (name) VALUES ("centos");
INSERT INTO lxc_templates (name) VALUES ("cirros");
INSERT INTO lxc_templates (name) VALUES ("debian");
INSERT INTO lxc_templates (name) VALUES ("fedora");
INSERT INTO lxc_templates (name) VALUES ("gentoo");
INSERT INTO lxc_templates (name) VALUES ("openmandriva");
INSERT INTO lxc_templates (name) VALUES ("opensuse");
INSERT INTO lxc_templates (name) VALUES ("oracle");
INSERT INTO lxc_templates (name) VALUES ("plamo");
INSERT INTO lxc_templates (name) VALUES ("sshd");
INSERT INTO lxc_templates (name) VALUES ("ubuntu");
