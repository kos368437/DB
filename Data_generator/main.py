import csv
import random
from math import ceil
from first import first
from random import shuffle
import datetime
import time

firsts = ['Каинская', 'Новосибирская', 'Зелёная', 'Звёздная', 'Грозовая',
          'Морозная', 'Тихая', 'Чудо', 'Живучая', 'Бодрая', 'Клинковая', 'Латная', 'Лучистая', 'Цепкая', 'Жгучая']
seconds = ['станица', 'заимка', 'деревня', 'речка', 'Каменушка', 'горка', 'роща', 'Нива', 'пасека', 'ферма', 'дамба',
           'лупа']

train_categories = ['express', 'freight', 'signature', 'suburban']

TRAINS_CNT = 1000
STATIONS_CNT = 180
TIMETABLE_CNT = 7000


def generate_stations():
    N = ceil(STATIONS_CNT / (len(firsts) * len(seconds)))
    stations = []
    id = 0
    for i in range(N):
        for first in firsts:
            for second in seconds:
                if i > 0:
                    stations.append((id, f'{first} {second} - {i}'))
                else:
                    stations.append((id, f'{first} {second}'))
                id += 1
                if id == STATIONS_CNT:
                    break
    return stations


def are_connected(frm, to, distances: dict):
    a = min(frm, to)
    b = max(frm, to)
    return ((a, b) in distances.keys() or a == b)


def get_connections(station, distances: dict):
    connected = set()
    for key in distances.keys():
        if station in key:
            connected_st_id = 0
            if key[0] == station:
                connected_st_id = 1
            connected.add(key[connected_st_id])
    return connected


def rec_create_route(frm_list: list, to, distances: dict):
    frm = frm_list[-1]
    connections = get_connections(frm, distances)
    connections = connections.difference(set(frm_list))
    for connection in connections:
        if are_connected(connection, to, distances):
            res = frm_list
            if connection != to:
                res.append(connection)
            res.append(to)
            return res
    for connection in connections:
        new_frm = frm_list.copy()
        new_frm.append(connection)
        res = rec_create_route(new_frm, to, distances)
        if res:
            return res
    return None


def create_route(frm, to, distances: dict):
    return rec_create_route([frm], to, distances)


def gen_routes_and_route_nodes(distances: dict):
    route_id = 0
    node_id = 0
    routes = []
    route_nodes = []
    for frm in range(STATIONS_CNT):
        for to in range(frm + 1, STATIONS_CNT):
            if random.randint(1, 10) <= 3:
                route_trace = create_route(frm, to, distances)
                if route_trace:
                    routes.append((route_id, f'{frm}-{to}'))
                    for i in range(len(route_trace)):
                        route_nodes.append((node_id, route_id, route_trace[i], i))
                        node_id += 1
                    route_id += 1
    return routes, route_nodes


def generate_distances():
    distances_list = []
    distances_dict = dict()
    id = 0
    for frm in range(STATIONS_CNT):
        for to in range(frm + 1, STATIONS_CNT):
            connected = (random.randint(1, 4) % 4) == 0
            if connected:
                distance = random.randint(5, 35)
                distances_list.append((id, frm, to, distance))
                distances_dict[(frm, to)] = distance
                id += 1
    return distances_list, distances_dict

def get_distance(frm, to, distances_dict: dict):
    a = min(frm, to)
    b = max(frm, to)
    if a == b:
        return 0
    else:
        return distances_dict[(a,b)]

def gen_trains(routes, route_nodes: list):
    trains = []
    for i in range(TRAINS_CNT):
        rand_route = routes[random.randint(0, len(routes) - 1)][0]
        rand_node = first(route_nodes, key=lambda x: (x[1] == rand_route))
        base_station = rand_node[2]
        capacity = random.randint(200, 500)
        category = train_categories[random.randint(0, len(train_categories) - 1)]
        trains.append((i, category, capacity, base_station, rand_route))
    return trains

def gen_random_time_between(frm:datetime, to:datetime):
    mintime_ts = int(time.mktime(frm.timetuple()))
    maxtime_ts = int(time.mktime(to.timetuple()))

    random_ts = random.randint(mintime_ts, maxtime_ts)
    return datetime.datetime.fromtimestamp(random_ts)
def gen_time():
    MINTIME = datetime.datetime(2010, 1, 1, 00, 00, 00)
    MAXTIME = datetime.datetime(2023, 6, 14, 23, 59, 59)
    mintime_ts = int(time.mktime(MINTIME.timetuple()))
    maxtime_ts = int(time.mktime(MAXTIME.timetuple()))

    random_ts = random.randint(mintime_ts, maxtime_ts)
    return datetime.datetime.fromtimestamp(random_ts)

def move_time(time:datetime, shift_minutes: int):
    return time + datetime.timedelta(minutes=shift_minutes)
def gen_timetable(trains, route_nodes, distences_dict):
    timetable = []
    id = 0
    delay_id = 0
    delays = []
    trip_num = 0
    for _ in range(TIMETABLE_CNT):
        rand_train = trains[random.randint(0, len(trains) - 1)]
        route_num = rand_train[4]
        capacity = rand_train[2]
        stations_list = [(node[2], node[3]) for node in filter(lambda x: x[1] == route_num, route_nodes)]
        stations_list.sort(key= lambda x: x[1])
        stations_list = [item[0] for item in stations_list]
        forward = random.randint(0, 1) == 0
        if not forward:
            stations_list = stations_list[::-1]

        arr_time = None
        start_time = gen_time()
        dep_time = start_time
        in_pass = random.randint(0, capacity)
        out_pass = 0
        total_passengers = in_pass

        timetable.append((id, rand_train[0], stations_list[0], forward, in_pass, 0, None, dep_time, total_passengers, trip_num))
        id += 1
        iter_stations = stations_list[1:-1]
        for i in range(len(iter_stations)):

            out_pass = random.randint(0, total_passengers)
            total_passengers -= out_pass
            in_pass = random.randint(0, capacity - total_passengers)
            total_passengers += in_pass

            distance = get_distance(iter_stations[i - 1], iter_stations[i], distances_dict)
            time_to_arrive = ceil(distance / 60)
            arr_time = move_time(dep_time, time_to_arrive + random.randint(0, 5))
            dep_time = move_time(arr_time, random.randint(5, 45))

            timetable.append((id, rand_train[0], iter_stations[i], forward, in_pass, out_pass, arr_time, dep_time, total_passengers, trip_num))
            id += 1

        distance = get_distance(stations_list[-2], stations_list[-1], distances_dict)
        time_to_arrive = distance
        finish_time = move_time(dep_time, time_to_arrive + random.randint(0, 5))
        timetable.append((id, rand_train[0], stations_list[-1], forward, 0, total_passengers, finish_time, None, 0, trip_num))
        id += 1

        trip_num += 1
        if random.randint(0, 1) == 0:
            delay_time = datetime.timedelta(minutes=random.randint(5,45))
            delays.append((delay_id, rand_train[0], forward, gen_random_time_between(start_time, finish_time), delay_time))
            delay_id += 1

    return timetable, delays




with open('stations.csv', 'w', newline='') as f:
    st_writer = csv.writer(f)
    stations = generate_stations()
    st_writer.writerows(stations)

with open('distances.csv', 'w', newline='') as f:
    dis_writer = csv.writer(f)
    distances_list, distances_dict = generate_distances()
    dis_writer.writerows(distances_list)

with open('routes.csv', 'w', newline='') as f, open('route_nodes.csv', 'w', newline='') as g:
    routes_writer = csv.writer(f)
    route_nodes_writer = csv.writer(g)
    routes, route_nodes = gen_routes_and_route_nodes(distances_dict)
    routes_writer.writerows(routes)
    route_nodes_writer.writerows(route_nodes)
with open('trains.csv', 'w', newline='') as f, open('timetable.csv', 'w', newline='') as g, open('delays.csv', 'w', newline='') as h:
    trains_writer = csv.writer(f)
    timetable_writer = csv.writer(g)
    delays_writer = csv.writer(h)
    trains = gen_trains(routes, route_nodes)
    timetable, delays = gen_timetable(trains, route_nodes, distances_dict)

    trains_writer.writerows(trains)
    timetable_writer.writerows(timetable)
    delays_writer.writerows(delays)