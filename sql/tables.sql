# 
# The tables that are being use in MUTAGEN version 4.+.
# 
# Kim Brugger (Nov 2003), contact: brugger@mermaid.molbio.ku.dk

#
# The users, groups and sessions tables
#

CREATE TABLE IF NOT EXISTS user (
  uid int(10) NOT NULL auto_increment primary key,
  grid int(10),
  name varchar(12) unique,
  fullname varchar(100),
  admin_mails enum('no', 'yes') NOT NULL DEFAULT 'no',
  email varchar(50),
  homepage varchar(50),
  profile varchar(150),
  password varchar(12),
  lasttime timestamp(14)
);

CREATE TABLE IF NOT EXISTS session (
  seid varchar(40) primary key,
  uid int(10) NOT NULL,
  hostname varchar(50),
  gracetime datetime,
  active int(1) DEFAULT 1
);

CREATE TABLE IF NOT EXISTS groups (
  grid int(10) NOT NULL auto_increment primary key,
  uids varchar(50),
  name varchar(12) unique
);

CREATE TABLE IF NOT EXISTS gene (
  gid       int(10) unsigned NOT NULL auto_increment primary key,
  sid       int(10) unsigned NOT NULL,
  fid       int(10) unsigned NOT NULL,
  name      varchar(100) NOT NULL,

  strand    int(1)  unsigned NOT NULL,
  start     int(10) unsigned NOT NULL,
  stop      int(10) unsigned NOT NULL, 
  intron    varchar(150) DEFAULT NULL,
  colour    int(4)  DEFAULT 0,

  cid       int(10) unsigned NOT NULL DEFAULT 0,
  cluster   varchar(100) NOT NULL,
  ccolour   int(4) DEFAULT 0,

  tid       int(10) unsigned NOT NULL DEFAULT 0,
  tid_score varchar(10) NOT NULL,

  link2gid  int(10) unsigned,

  type      varchar(30),
  score int(10) unsigned DEFAULT NULL,
  altstart  int(1) unsigned DEFAULT 0,

  show_gene ENUM('show', 'deleted') DEFAULT 'show',

  old_gid   int(10) unsigned DEFAULT NULL,

  index orf_sid  (sid),
  index orf_stop (stop)
);

CREATE TABLE IF NOT EXISTS genefinder (
  fid       int(10) unsigned NOT NULL auto_increment primary key,

  gid       int(10) unsigned,
  sid       int(10) unsigned NOT NULL,
  name      varchar(100) NOT NULL,

  strand    int(1)  unsigned NOT NULL,
  start     int(10) unsigned NOT NULL,
  stop      int(10) unsigned NOT NULL,
  intron    varchar(150) DEFAULT NULL,
  
  type      varchar(30),
  score float(10) unsigned DEFAULT NULL,

  source    varchar(50) NOT NULL,    

  index orf_sid  (sid),
  index orf_gid  (gid),
  index orf_stop (stop)
);

CREATE TABLE IF NOT EXISTS annotation (
  aid           int(10) unsigned NOT NULL auto_increment primary key, 
  gid           int(10) unsigned,
  fid           int(10) unsigned DEFAULT NULL, 

  datetime      timestamp NOT NULL,
  gene_name     varchar(25),
  start_codon   int(2),
  conf_in_gene  varchar(30),


  EC_number     varchar(25),
  conf_in_func  varchar(30),

  gene_product  varchar(250),
  comment       text,
  evidence      varchar(250),

  general_function varchar(250),

  TAG           int(1) DEFAULT 0,
  final         int(1) DEFAULT 0,

  annotator_name varchar(50),
  uid int(10),
  state ENUM('show','deleted') DEFAULT 'show',

  index gid_index (gid)
);

CREATE TABLE IF NOT EXISTS adc (
  gid       int(10) unsigned NOT NULL,
  name      varchar(150),
  score     varchar(10),
  source    varchar(10) NOT NULL,
  other     varchar(200),
  report    longtext,

  PRIMARY KEY (gid, source)
);

CREATE TABLE IF NOT EXISTS sequence (
  sid       int(10) unsigned NOT NULL auto_increment primary key,
  oid       int(10) unsigned NOT NULL,
  vid       int(10) unsigned NOT NULL,
  name      varchar(150),
  sequence  longtext,


  index org (oid),
  index ver (vid)
);

CREATE TABLE IF NOT EXISTS organism (
  oid   int(10) unsigned NOT NULL auto_increment primary key,
  name  varchar(100),
  alias varchar(10),
  grids varchar(50),
  type  enum('organism', 'virus', 'plasmid') NOT NULL DEFAULT 'organism',

  tax       int(10) unsigned NOT NULL
);

CREATE TABLE IF NOT EXISTS version (
  vid int(10) unsigned NOT NULL auto_increment primary key,
  oid int(10) unsigned NOT NULL,
  version int(10)
);

CREATE TABLE IF NOT EXISTS pathway (
  pid int(10) NOT NULL auto_increment primary key,
  
  name varchar(25),
  oid int(10) unsigned NOT NULL,
  vid int(10) unsigned NOT NULL,
  description varchar(100),
  picture longblob,

  key `k_vid`  (`vid`),
  key `k_oid`  (`oid`),
  key `k_name` (`name`)
);

CREATE TABLE IF NOT EXISTS pathway_gid (
  pid int(10) NOT NULL,
  gid int(10) NOT NULL,
  EC  varchar(25),

  PRIMARY key k_gid (gid, pid)
);


#CREATE TABLE IF NOT EXISTS  (
#
#);

#CREATE TABLE IF NOT EXISTS  (
#
#);


#CREATE TABLE IF NOT EXISTS  (
#
#);


#insert into groups (uids, name) values ("1","admin");
#insert into groups (uids, name) values ("1","user");
#insert into groups (uids, name) values ("1","compare");
#insert into user (grid, name, password) values ("1", "admin", "admin");
