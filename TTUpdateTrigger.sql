CREATE OR REPLACE FUNCTION tt_update_train_st() RETURNS TRIGGER AS $tt_train_st_trigger$
    BEGIN
        if (NEW.station_id in (SELECT r_n.station_id FROM trains t INNER JOIN route_node r_n ON t.num = NEW.t_num and t.m_num = r_n.m_num))
            THEN
            RETURN NEW;
        else
            RAISE NOTICE 'INCORRECT STATION % FOR GIVEN TRAIN %: THERE IS NO SUCH STATION IN TRAINS ROUTE', new.station_id, new.t_num;
            RETURN NULL;
        end if;
    END;
$tt_train_st_trigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tt_train_st_trigger
BEFORE INSERT OR UPDATE ON timetable
    FOR EACH ROW EXECUTE FUNCTION tt_update_train_st();