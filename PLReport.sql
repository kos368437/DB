-- -- DROP FUNCTION IF EXISTS extended_sales(p_itemno int);
-- -- CREATE FUNCTION  extended_sales(p_itemno int)
-- -- RETURNS jsonb AS $$
-- -- BEGIN
-- --    DROP TABLE IF EXISTS v_arr;
-- --     CREATE TEMP TABLE v_arr AS SELECT json_build_object(d.id, json_build_object('distance', d.distance))::jsonb as data from distances d;
-- --     SELECT v_arr.data[to_json(10)] into x FROM v_arr;
-- --     return x;
-- -- END;
-- -- $$ LANGUAGE plpgsql;
-- -- SELECT * FROM extended_sales(1);
-- -- DROP TYPE IF EXISTS t_d;
-- -- DROP TYPE IF EXISTS t_lag;
-- -- CREATE TYPE t_d as (id int, distance int);
-- -- CREATE TYPE t_lag as (id int, t_id int, lag int);
-- CREATE TYPE d_p_c_m as (date_ text, passengers int, trips_count int, pass_milleage int);

DROP FUNCTION IF EXISTS report();
CREATE FUNCTION  report()
RETURNS d_p_c_m[] AS $$
    DECLARE
        distance_arr distances[];
        timetable_arr timetable[];
        t_lag_arr t_lag[];
        t_d_arr t_d[];
        d_p_c_m_arr d_p_c_m[];
        quart_arr d_p_c_m[];
        year_arr d_p_c_m[];
        total d_p_c_m[];
        out d_p_c_m[];
BEGIN
    distance_arr := ARRAY(SELECT distances FROM distances);
    timetable_arr := ARRAY(SELECT timetable FROM timetable);
    t_lag_arr := ARRAY(SELECT (t.id, t.station_id, lag(t.station_id, 1) over (partition by t.trip_num ORDER BY coalesce(t.dep_time, t.arr_time))) FROM unnest(timetable_arr) t ) ;
    t_d_arr := ARRAY(SELECT (l.id, d.distance) FROM unnest(t_lag_arr) l INNER JOIN unnest(distance_arr) d ON ((d.from_st = l.t_id) AND (d.to_st = l.lag)) OR ((d.from_st = l.lag) AND (d.to_st = l.t_id)));
    d_p_c_m_arr := ARRAY (SELECT (t.arr_time::date, t.out_pass, t.id, (total_pass - in_pass + out_pass) * distance) FROM unnest(timetable_arr) t INNER JOIN unnest(t_d_arr) t_d ON t.id = t_d.id);
    out := ARRAY (SELECT (date_, sum(passengers), count(trips_count), sum(pass_milleage)) FROM unnest(d_p_c_m_arr) group by date_);
    quart_arr := ARRAY(SELECT(concat(extract(year from to_date(date_, 'YYYY-MM-DD')):: text || '-' || to_char(to_date((floor((extract(month from to_date(date_, 'YYYY-MM-DD')) + 2)/3)*3)::text, 'MM'), 'MM') || '-32'), passengers, trips_count, pass_milleage) FROM unnest(out));
    year_arr := ARRAY(SELECT(concat(extract(year from to_date(date_, 'YYYY-MM-DD')):: text || '-12-33'), passengers, trips_count, pass_milleage) FROM unnest(out));
    quart_arr := ARRAY (SELECT (date_, sum(passengers), sum(trips_count), sum(pass_milleage)) FROM unnest(quart_arr) group by date_);
    year_arr := ARRAY (SELECT (date_, sum(passengers), sum(trips_count), sum(pass_milleage)) FROM unnest(year_arr) group by date_);
    total := ARRAY (SELECT ('1900-total'::text, sum(passengers), sum(trips_count), sum(pass_milleage)) FROM unnest(year_arr) group by date_);
    total := ARRAY (SELECT (date_, sum(passengers), sum(trips_count), sum(pass_milleage)) FROM unnest(total) group by date_);
    out := out || quart_arr || year_arr || total;
    return out;
--     SELECT * FROM distance_arr INNER JOIN timetable_arr ON 1;
--     return query SELECT * FROM unnest(t_d_arr);
END;
$$ LANGUAGE plpgsql;
SELECT * FROM unnest(report());