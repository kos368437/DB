CREATE OR REPLACE FUNCTION route_num_insert() RETURNS TRIGGER AS $route_num_insert_trigger$
    DECLARE
        route_mins int[];
        route_max int;
        transit_mins int[];
        transit_max int;
        min_gr_max int;
        num int;
    BEGIN
        if NEW.name is null then
            route_mins := ARRAY ((SELECT route_num  FROM (SELECT route_num, (lead(route_num) over (ORDER BY route_num) - route.route_num) as dis FROM route) dis_s WHERE dis > 1));
            route_max := (SELECT max(route_num) FROM route);

            if route_max is null then
                route_max := -1;
            end if;

            transit_mins := ARRAY((SELECT t_id FROM (SELECT t_id, (lead(t_id) over (ORDER BY t_id) - transit.t_id) as dis FROM transit) dis_s WHERE dis > 1));
            transit_max := (SELECT max(t_id)  FROM transit);
            if transit_max is null then
                transit_max := -1;
            end if;

            if route_max > transit_max then
                min_gr_max := (SELECT min(t.rm) FROM (SELECT rm.rm FROM unnest(route_mins) rm where rm.rm > transit_max) t);
                if min_gr_max is null then
                    min_gr_max := route_max + 1;
                end if;
            elseif transit_max > route_max then
                min_gr_max := (SELECT min(t.rm) FROM (SELECT rm.rm FROM unnest(transit_mins) rm where rm.rm > route_max) t);
                if min_gr_max is null then
                    min_gr_max := transit_max + 1;
                end if;
            else
                min_gr_max := transit_max + 1;
            end if;

            num := (SELECT min(rm.rm) FROM unnest(route_mins) rm INNER JOIN unnest(transit_mins) tm ON rm.rm = tm.tm);
            if num is null then
                num := min_gr_max;
            end if;
            new.name := num;
        end if;
        return new;
    END;
$route_num_insert_trigger$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER route_num_insert_trigger
BEFORE INSERT OR UPDATE ON route
    FOR EACH ROW EXECUTE FUNCTION route_num_insert();