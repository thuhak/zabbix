CREATE OR REPLACE FUNCTION delete_interface_trigger()
RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        DELETE FROM dhosts USING dservices WHERE dhosts.dhostid = dservices.dhostid AND dservices.IP = OLD.ip;
    END IF;
    RETURN ;
END;
$$
LANGUAGE plpgsql VOLATILE;

ALTER FUNCTION delete_interface_trigger() OWNER TO zabbix;

CREATE TRIGGER interface_delete_trigger AFTER DELETE ON interface FOR EACH ROW EXECUTE PROCEDURE delete_interface_trigger();

