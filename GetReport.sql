SELECT date, total_trips, total_passengers, total_pass_milleage
FROM (SELECT case
                 when (trip_date is not null)
                     then trip_date::varchar
                 when (trip_date is null and quartal is not null)
                     then concat(year_, '-', to_char(to_date((quartal * 3)::text, 'MM'), 'MM') , '-32')
                 when (quartal is null and year_ is not null)
                     then concat(year_::varchar, '-12-33')
                 else 'total'
                 end date_sort,

             case
                 when (trip_date is not null)
                     then trip_date::varchar
                 when (trip_date is null and quartal is not null)
                     then concat('Q', quartal, ' ', year_::varchar)
                 when (quartal is null and year_ is not null)
                     then year_::varchar
                 else 'total'
                 end date,

             *
      FROM (SELECT year_,
                   quartal,
                   trip_date,
                   sum(trips)         as total_trips,
                   sum(passengers)    as total_passengers,
                   sum(pass_mileage_) as total_pass_milleage
            FROM (SELECT *,
                         floor((extract(month from trip_date) - 1) / 3) + 1 as quartal,
                         extract(year from trip_date)                 as year_
                  FROM (SELECT arr_time::date as trip_date,
                               count(*)          trips,
                               sum(out_pass)     passengers,
                               sum(pass_mileage) pass_mileage_
                        FROM (SELECT (total_pass - in_pass + out_pass) * distance pass_mileage, *
                              FROM (SELECT LEAST(prev_st, prevs.station_id)    least,
                                           GREATEST(prev_st, prevs.station_id) greatest,
                                           *
                                    FROM (SELECT *
                                          FROM (SELECT lag(station_id, 1)
                                                       over (partition by trip_num order by coalesce(arr_time, dep_time)) prev_st,
                                                       *
                                                FROM timetable t1) r
                                          WHERE prev_st IS NOT NULL) as prevs) as sort_prevs
                                       INNER JOIN distances d on d.from_st = least and d.to_st = greatest) total_pass_mil
                        group by arr_time::date) rep) rlp
            group by rollup (year_, quartal, trip_date)) lll
      order by date_sort) format
