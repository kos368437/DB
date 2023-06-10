-- DROP function update_by_delay(date_ date);
create or replace PROCEDURE update_by_delay(date_ date)AS $$
DECLARE
    delay_curs CURSOR FOR SELECT * FROM delays WHERE rec_time::date = date_;
    tt_curs CURSOR (e_train int, e_fwd bool, e_time timestamp) FOR
        SELECT tt.* FROM (SELECT r_n.*, trip_num FROM (SELECT *
                       FROM (SELECT *,
                                    min(extract(epoch from dep_time - e_time)) over () min_dep_t_dist,
                                    extract(epoch from dep_time - e_time)              dep_t_dist,
                                    min(extract(epoch from timetable.arr_time - e_time)) over () min_arr_t_dist,
                                    extract(epoch from timetable.arr_time - e_time)              arr_t_dist
                             FROM timetable
                             WHERE t_num = e_train
                               and forward = e_fwd
                               and (dep_time > e_time or arr_time > e_time)
                               and dep_time::date = e_time::date
                               and extract(epoch from dep_time - e_time) > 0 or extract(epoch from timetable.arr_time - e_time)  > 0) same_date_tt
                       WHERE ((dep_t_dist = min_dep_t_dist) and (min_arr_t_dist > min_dep_t_dist)) OR (arr_t_dist = min_arr_t_dist)
                   ) needed_trip inner join trains tr ON t_num = tr.num INNER JOIN route_node r_n ON tr.m_num = r_n.m_num and r_n.station_id = needed_trip.station_id) r_node
                   INNER JOIN route_node r_n2 ON r_n2.m_num = r_node.m_num and (((r_n2.order_ >= r_node.order_) and e_fwd) OR ((not e_fwd) and ((r_n2.order_ <= r_node.order_)))) INNER JOIN timetable tt ON tt.trip_num = r_node.trip_num AND r_n2.station_id = tt.station_id;
    begin

    FOR rec in delay_curs LOOP
        FOR tt_node in tt_curs (rec.t_num, rec.forward, rec.rec_time) LOOP
            IF extract(epoch FROM tt_node.arr_time - rec.rec_time) > 0 THEN
                UPDATE timetable SET arr_time = arr_time + rec.delay_time WHERE id = tt_node.id;
            end if;
            UPDATE timetable SET dep_time = dep_time + rec.delay_time WHERE id = tt_node.id;
        end loop;
       UPDATE delays SET delay_time = make_interval(0) WHERE CURRENT OF delay_curs;
    end loop;
end;
$$ LANGUAGE plpgsql;
ALTER PROCEDURE update_by_delay(date_ date) SET enable_partition_pruning to off;
CALL update_by_delay(to_date('2010-01-06', 'YYYY-MM-DD'));