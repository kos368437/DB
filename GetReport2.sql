SELECT lag(station_id) over (partition by trip_num order by arr_time) prev_st, *
                              FROM timetable t1