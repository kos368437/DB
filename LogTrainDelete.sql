CREATE TABLE IF NOT EXISTS del_trains_log(LIKE trains, pass_cnt int, tickets_cnt int);
CREATE OR REPLACE FUNCTION trains_log_delete() RETURNS TRIGGER AS $trains_log_delete_trigger$
    DECLARE
        pass_cnt int;
        ticket_cnt int;
        log_row del_trains_log%rowtype;
    BEGIN
        pass_cnt := (SELECT sum(in_pass) FROM (SELECT in_pass FROM timetable WHERE t_num = old.num) tt);

        ticket_cnt := (SELECT count(*) FROM ticket INNER JOIN (SELECT id FROM timetable WHERE t_num = old.num) tt ON ticket.frm_st_tt_id = tt.id);
--         RAISE NOTICE 'DELETED train with total % passengers and % tickets', pass_cnt, ticket_cnt;
        log_row := old;
        log_row.pass_cnt := pass_cnt;
        log_row.tickets_cnt := ticket_cnt;
        INSERT INTO del_trains_log SELECT log_row.* ;
        return old;
    END;
$trains_log_delete_trigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trains_log_delete_trigger
BEFORE DELETE ON trains
    FOR EACH ROW EXECUTE FUNCTION trains_log_delete();