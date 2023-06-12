CREATE OR REPLACE FUNCTION tt_check_arr_time() RETURNS TRIGGER AS $tt_check_arr_time_trigger$
    DECLARE
        prev_st int;
        prev_tt record;
        r_node record;
        step_forward int;
        common_time_interval_val int;
        common_time_interval interval;
        prev_time timestamp;
        tt_curs CURSOR (tt_trip_num int, rn_m_num int, rn_order int, tt_t_num int) FOR SELECT tt.* FROM route_node r_n INNER JOIN timetable tt ON r_n.m_num = rn_m_num and r_n.order_ > rn_order and tt.trip_num = tt_trip_num and tt.t_num = tt_t_num and r_n.station_id = tt.station_id ;
        INTERVAL_CONST interval := make_interval(hours := 1);
        DEP_INTERVAL_CONST interval := make_interval(mins := 15);

        dep_arr_interval interval;
    BEGIN
        IF new.forward THEN
            step_forward := 1;
        ELSE
            step_forward := -1;
        end if;
        SELECT r_n.* INTO r_node FROM trains t INNER JOIN route_node r_n ON (t.num = new.t_num) and (r_n.m_num = t.m_num) and (new.station_id = r_n.station_id);
        prev_st := (SELECT station_id FROM route_node r_n WHERE r_node.m_num = r_n.m_num AND r_node.order_ = r_n.order_ + step_forward);
        SELECT * INTO prev_tt FROM timetable tt WHERE tt.trip_num = new.trip_num AND tt.station_id = prev_st;
        if prev_tt IS NULL then
            return new;
        ELSEIF (extract(epoch from prev_tt.dep_time  - new.arr_time) < 0)  THEN
            return new;
        ELSE
--             if (extract(epoch from new.arr_time  - new.dep_time) >= 0) THEN
--                 new.dep_time := new.arr_time + make_interval(0,0,0,0,0,15,0);
--             end if;
            common_time_interval_val := (SELECT avg(extract(epoch from to_tt.arr_time - from_tt.dep_time)) FROM timetable from_tt INNER JOIN timetable to_tt ON (from_tt.station_id = new.station_id) and (to_tt.station_id = prev_st) and (from_tt.trip_num = to_tt.trip_num) and (from_tt.dep_time < to_tt.arr_time));
            if common_time_interval_val is null THEN
                common_time_interval := INTERVAL_CONST;
            ELSE
                common_time_interval := make_interval(secs := common_time_interval_val);
            end if;
            dep_arr_interval := new.dep_time - new.arr_time;
            if extract(epoch from dep_arr_interval) < 0 then
                dep_arr_interval := DEP_INTERVAL_CONST;
            end if;
            new.arr_time := prev_tt.dep_time + common_time_interval;
            if new.dep_time is not null then
                new.dep_time := new.dep_time + common_time_interval;
                if extract(epoch from new.dep_time - new.arr_time) < 0 then
                    new.dep_time := new.arr_time + dep_arr_interval;
                end if;
            end if;
--         prev_time := new.dep_time;
--         FOR rec in tt_curs (new.trip_num, r_node.m_num, r_node.order_, new.t_num) LOOP
--             UPDATE timetable SET arr_time = arr_time + common_time_interval WHERE id = rec.id;
--             if rec.dep_time is not null then
--                 UPDATE timetable SET dep_time = dep_time + common_time_interval WHERE id = rec.id;
--             end if;
--         end loop;
            return new;
        end if;
    END;
$tt_check_arr_time_trigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER tt_check_arr_time_trigger
BEFORE INSERT OR UPDATE ON timetable
    FOR EACH ROW EXECUTE FUNCTION tt_check_arr_time();