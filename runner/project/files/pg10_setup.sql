CREATE OR REPLACE FUNCTION f_role( rolename text, password text )
RETURNS VOID
AS
$BODY$
DECLARE
   query text;
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = rolename) THEN
      query := 'CREATE ROLE ' || rolename || ' LOGIN PASSWORD ''' || password || ''';';
      EXECUTE query;      
   END IF;
END
$BODY$
LANGUAGE plpgsql;


SELECT f_role('scm', 'password');
SELECT 'CREATE DATABASE scm OWNER = scm LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'scm')\gexec

SELECT f_role('rman', 'password');
SELECT 'CREATE DATABASE rman OWNER = rman LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rman')\gexec

SELECT f_role('rangerkms', 'password');
SELECT 'CREATE DATABASE ranger OWNER = rangerkms LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ranger')\gexec

SELECT f_role('hue', 'password');
SELECT 'CREATE DATABASE hue OWNER = hue LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hue')\gexec

SELECT f_role('hive', 'password');
SELECT 'CREATE DATABASE hive OWNER = hive LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'hive')\gexec
ALTER DATABASE hive SET standard_conforming_strings=off;

SELECT f_role('oozie', 'password');
SELECT 'CREATE DATABASE oozie OWNER = oozie LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'oozie')\gexec
ALTER DATABASE oozie SET standard_conforming_strings=off;

SELECT f_role('das', 'password');
SELECT 'CREATE DATABASE das OWNER = das LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'das')\gexec

SELECT f_role('schemaregistry', 'password');
SELECT 'CREATE DATABASE schemaregistry OWNER = schemaregistry LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'schemaregistry')\gexec

SELECT f_role('smm', 'password');
SELECT 'CREATE DATABASE smm OWNER = smm LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'smm')\gexec

SELECT f_role('qproc', 'password');
SELECT 'CREATE DATABASE qproc OWNER = qproc LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'qproc')\gexec

-- SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN
SELECT f_role('qmadmin', 'password');
SELECT 'CREATE DATABASE configstore OWNER = qmadmin LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'configstore')\gexec

SELECT f_role('streamsmsgmgr', 'password');
SELECT 'CREATE DATABASE streamsmsgmgr OWNER = streamsmsgmgr LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'streamsmsgmgr')\gexec

SELECT f_role('oozie', 'password');
SELECT 'CREATE DATABASE oozie OWNER = oozie LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'oozie')\gexec

SELECT f_role('ssb_admin', 'password');
SELECT 'CREATE DATABASE ssb_admin OWNER = ssb_admin LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ssb_admin')\gexec

SELECT f_role('ssb_mve', 'password');
SELECT 'CREATE DATABASE ssb_mve OWNER = ssb_mve LC_CTYPE = ''C.UTF-8'' LC_COLLATE = ''C.UTF-8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ssb_mve')\gexec
