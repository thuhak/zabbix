CREATE OR REPLACE FUNCTION delete_dhost(ip VARCHAR) RETURNS VOID AS $$
BEGIN
	PERFORM 'DELETE FROM dhosts USING dservices WHERE dhosts.dhostid = dservices.dhostid AND IP = ' || queto_literal(ip);
END;
$$ LANGUAGE plpgsql;

ALTER FUNCTION delete_dhost(VARCHAR) OWNER TO zabbix;