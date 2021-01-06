drop database if exists casbin;
CREATE DATABASE casbin;

USE casbin;

CREATE TABLE IF NOT EXISTS casbin_rule (
    id int AUTO_INCREMENT NOT NULL,
    p_type VARCHAR(100) NOT NULL,
    v0 VARCHAR(100),
    v1 VARCHAR(100),
    v2 VARCHAR(100),
    v3 VARCHAR(100),
    v4 VARCHAR(100),
    v5 VARCHAR(100),
    primary key (id)
    );

INSERT INTO casbin_rule(p_type, v0, v1, v2, v3, v4, v5) VALUES
('p', 'dajun', 'data1', 'read', '', '', ''),
('p', 'lizi', 'data2', 'write', '', '', '');