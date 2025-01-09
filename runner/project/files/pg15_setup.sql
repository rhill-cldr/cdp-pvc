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

SELECT f_role('airflow', 'airflow');
SELECT 'CREATE DATABASE airflow OWNER = airflow LC_CTYPE = ''C.utf8'' LC_COLLATE = ''C.utf8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'airflow')\gexec

ALTER USER airflow WITH PASSWORD 'password';

