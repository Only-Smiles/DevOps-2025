
CREATE DATABASE minitwit;

USE minitwit;

CREATE TABLE user (
  user_id integer primary key auto_increment,
  username varchar(100) not null,
  email varchar(200) null,
  pw_hash varchar(200) not null
);

CREATE TABLE follower (
  who_id integer,
  whom_id integer
);

CREATE TABLE message (
  message_id integer primary key auto_increment,
  author_id integer not null,
  text varchar(500) not null,
  pub_date integer,
  flagged integer
);