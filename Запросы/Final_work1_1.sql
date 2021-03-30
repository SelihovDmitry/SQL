 1. � ����� ������� ������ ������ ���������?
 
 select city, count(airport_code) as cnt --�������� ������ � ���������� ����������
 from airports
 group by city --���� ������������ group by �.�. �������������� ���������� �������
 having count(airport_code) > 1 --��������� ��, ��� ���������� ������ 1
 order by cnt --���������
 
 
  2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?
 
 
 ������ �������
 
 /*
  * ����� ������� ��� ��� ����������� 3 �������: aircrafts - ����� ����� ������ ������������ ���������,
  * airports, �.�. ���� ������� �������� ��������� � ������� flights ��� ����� ����� ����.
  */
 select a.airport_name, a2.model, range --�������� ������ ������� ��� ������
 from airports a 
 join flights f on a.airport_code = f.departure_airport -- ��� � ������ ������� � ������ �������� ������� flights 
 -- ������ join departure_airport ��� arrival_airport, �.�. � ����� ������ ���� ������� ��������, �� �� � ������ � ��������
 join aircrafts a2 on f.aircraft_code = a2.aircraft_code 
 where "range" = (select max(a2."range") from aircrafts a2) -- ��������� ����� ����� �����, ����������� ��������� � ������������
 group by a.airport_name, a2.model, range -- ����������
 -- �� ��� ������� ���� ������ �� �����������, �.�. �� ��������� ������� �� ����� ������� � ������ ��� ��������� ������ ���
 
 
 ������ �������
 
 select a.airport_name, mr.model, range
 from (
 	select a2.aircraft_code, a2.model, a2."range" 
	from aircrafts a2 
	where "range" = (select max(a2."range") from aircrafts a2)
 	) as mr -- �������� ������� � ����� ������� ����������
 left join flights f on f.aircraft_code = mr.aircraft_code
 left join airports a on f.departure_airport = a.airport_code 
 group by a.airport_name, mr.model, range
 -- �������� ����� ������� ��� ������, �.�. ������� where ������ ��� "���������" ������� 
 -- � ����� �� ������������ ������ ������ ������
 
 
  3. ������� 10 ������ � ������������ �������� �������� ������
 
 select flight_id, flight_no, scheduled_departure, actual_departure, 
 	(actual_departure - scheduled_departure) as delay
 from flights -- ������� �������� ���������� �� ����� � ����� ��������
 where actual_departure is not null -- ������� null �������� (�������� ���� ������� ��� �� �������, �� actual_departure ����� null)
 order by delay desc --��������� �� ��������
 limit 10 -- ��������� ������ 10
 
 
 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?

select b.book_ref, bp.ticket_no 
from bookings b
left join tickets t on t.book_ref = b.book_ref
left join boarding_passes bp on t.ticket_no = bp.ticket_no --������ ������ left join, �.�. ���� �������� ��������� �������
--������� � � ��� ������������ ���������� ������
where bp.ticket_no is null --���� � ������ ��� ������, �� ticket_no �� ������� ������� ����� null, ��� ��� � �����
--group by b.book_ref, bp.ticket_no --��������� ���������� ������������, �� ��� ����������� ����� ������� 5 ���,
--�.�. ������ �� ������� ������ (����� ����� �� ��� ���), ��� ����������� ����� �� ������������. ����� ����� ����.
 

5. ������� ��������� ����� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� �� ��������� �� ����. 
�.�. � ���� ������� ������ ���������� ����� - ������� ������� ��� �������� �� ������� ��������� �� 
���� ��� ����� ������ ������ �� ����������� ����

select f.flight_id, f.flight_no, f.aircraft_code, allst.allseats, count(bp.seat_no) as busy_seats, --�������� ������� ��� ������
	allst.allseats - count(bp.seat_no) as free_seats, -- ������� ����� ��������� ����, count(bp.seat_no) - ����� ������� ���� � �����
	round(((allst.allseats - count(bp.seat_no))::numeric(5,2) / allst.allseats), 4)*100 as percent_free, -- ������� �������
	--�������� � numeric ����� ������� ���� �������, � ������� round ��������� �������� �� ����� ����� ��������
	f.actual_departure::date, --�������� � ����, ��� ������� � ������
	f.departure_airport,
	a2.airport_name, 
	sum(count(bp.seat_no)) over(partition by f.actual_departure::date, f.departure_airport order by f.actual_departure, f.departure_airport)
		as depart_people -- ���������� order by, ��� ��� � ������� ������� � ������ ������ ���������� ����� �� ����, � �� ����������
		--� �������� ���� �������� ����, ����� ��� ���� ����������, �������� � ����, ��� �����, ���, ���.
from flights f
left join airports a2 on f.departure_airport = a2.airport_code --��������� ����� ������� �������� ���������
left join ticket_flights tf using(flight_id) --������������� ������� ����� ��������� �� boarding_passes
left join boarding_passes bp using(ticket_no, flight_id) --������������ ����� ������ ������� ���� � ����� ������
join (select s.aircraft_code, count(s.seat_no) as allseats
		from seats s
		group by s.aircraft_code) as allst on f.aircraft_code = allst.aircraft_code --� ����� ���� �� ����� ������, ������������ �������
		--� ������������ ������������ ���������, ����� �������� � �� ������� �������, �� � ���� ��� ����������
group by f.flight_id, f.flight_no, f.aircraft_code, allst.allseats, a2.airport_name --�����������, ����� ��������� ������� count(bp.seat_no)
--p.s. ������ ����������� �������� �����, 3.5 - 4 ���. �������� ����� ���-�� ��������������,
--p.p.s � ����� ���� ������ ���� 3.


6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

/*
 * ��� ���� �������� ���-�� ��������� � ������ ����� �������� �� ����� ���-�� ���������
 * ����� � ��� 8 ����� ���������, ������ � �������������� ������� ������ ���������� 8 �����
 * ������ ����� �������� ����� ��������� 100
 * � ���������� ������� ����� ���-�� ���������
 */

select aircraft_code, 
	round(count(aircraft_code)::numeric(10,2) / 
		(select count(flight_id) from flights f2 ), 4)*100 as percent_aircraft
from flights f
group by aircraft_code

--��������, ������������� �� ���������� 100
with cte_1 as 
(
	select aircraft_code, 
		round(count(aircraft_code)::numeric(10,2) / 
			(select count(flight_id) from flights f2 ), 4)*100 as percent_aircraft
	from flights f
	group by aircraft_code
)
select sum(cte_1.percent_aircraft) from cte_1
-- ��� �����, ����������� � 0.01 ��-�� ����������.


7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

with amount_business as --������� �������� � ������ �� ������ ����� 
(
	select tf.amount as business, tf.fare_conditions, tf.flight_id, tf.ticket_no 
	from ticket_flights tf 
	where fare_conditions = 'Business'
)
select amount_business.business, amount_economy.economy 
from amount_business
join ( --����������� � ��� �� flyght_id �������� � ������ �� ������ �����
		select flight_id, amount as economy
		from ticket_flights
		where fare_conditions = 'Economy'
	) amount_economy on amount_business.flight_id = amount_economy.flight_id
where amount_business.business < amount_economy.economy --����������� ������� ������ - ���� ������ ������� �������
--����� ���������, � �����. � ������� ���. ���� �� ��� ���� �� ����� ������������ �������
--flights � airports (2 ���� - ����� ����� ������ � ����� �������) ��� ������ ������� ������ � ���� ����.

�� ������� ������� (����������� ������ ������ � �������) ��� ��� ����������� � ��������,
������� ����� �������� � < �� > � ������� ����������.

with amount_business as
(
select tf.flight_id, tf.fare_conditions, tf.amount as amount_business, dep.city as from, arr.city as to
from ticket_flights tf, flights f, airports arr, airports dep
where f.flight_id = tf.flight_id
	and f.departure_airport = dep.airport_code 
	and f.arrival_airport = arr.airport_code
	and tf.fare_conditions = 'Business'
) --����� ������� �������� � ������ �� ������ ����� �� � �������� ������ � ������� 
select amount_business.flight_id, 
	amount_business.amount_business, amount_economy.amount_economy,
	amount_business.from, amount_business.to
from amount_business
	join (
		select tf.flight_id, tf.fare_conditions, tf.amount as amount_economy, dep.city as from, arr.city as to
		from ticket_flights tf, flights f, airports arr, airports dep
		where f.flight_id = tf.flight_id
			and f.departure_airport = dep.airport_code 
			and f.arrival_airport = arr.airport_code
			and tf.fare_conditions = 'Economy'
		) amount_economy on amount_business.flight_id = amount_economy.flight_id
		--����� ����������� � ��� �� flyght_id �������� � ������ �� ������ ����� �� � �������� ������ � �������
where amount_business.amount_business < amount_economy.amount_economy --�� �� ���� ������ ������� �������, �� ��� ������� ����� �������������
group by amount_business.flight_id, 
	amount_business.amount_business, amount_economy.amount_economy,
	amount_business.from, amount_business.to  
	--�� ����� �� ����� �� ������������ � ������ ������ � ������� ����, �.�. ����� ������� ���, ������������� join'���
	--������� ��� �� ������ �������. ��� � ����� �������, � ������ ����� ����� ����� ��������� � ������ ������ ����� ����� �������������.
	
�.�. � ����� ������ � ���� � ���� ����� ������� 2 �������� � ������ �� ������ � ������ � � ������ ����������� 
��� ���� �� ������ ������ ��� �� ������


8. ����� ������ �������� ��� ������ ������?
- ��������� ������������ � ����������� FROM
- �������������
- �������� except

��������� ����������� ��� ���������� �������� ����������.

�� �������� ��� ���� �� ������-�� ��������� ���� ������ � ������������ �����, �� ���� � ������� ������

����� ���������� � ���:

select count(city) from airports a --104

�� �� ������� �� 1 ������ ��� � ���������� 2 ���������, � � ������ 3, �.�. ������� ����� 104 - 3 = 101
�.�. ����� ������ ������� ������ ���� 101 * 101 = 10201.
������� ��� ��� �����, ��� ����� ������� �������� ������������� ��� ����� ������� ������ ������ � ������� ������ �� ����������:

create or replace view routes1 
as select f.departure_airport, dep.city AS departure_city,
	f.arrival_airport, arr.city AS arrival_city
from flights f, airports dep, airports arr --��������� 2 ���� � �������� ���������� (����� �������� ������ � �������), �� ��� ����� �����
where f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code;

select * from routes1 r

������� �� ����� ���������� ������� �������, ��� ���� ��������� (��������� ������������)

select r1.departure_city, a.city
from routes1 r1, airports a --��������� ������������
group by r1.departure_city, a.city 
order by r1.departure_city

���������� 10201 ������, ��� �� � ��������. �� ��� ���� ����� ��������, � ���� ���� ��� ������ ������� �� ������ � � ���� �� ������,
� ����� ������ �� - ��� �������, � ������������ ����� ������ - � �� ��� ������ ������, 
�.�. � ��� ������� ��� ��� ������ ������ �� ������� � ������ ���., �� �� ����� ������� ��� � ����� �� ��� ���������� Postgre.

������� � ���������� ����������:

select r1.departure_city, r1.arrival_city
from routes1 r1 
group by r1.departure_city, r1.arrival_city 
order by r1.departure_city

516 ����� - 516 ������ ��������� ���������, � ������ �������, ����� �������� ���� ������ �����, ��������� ����� ���� ������
�� �� ���������� ���������� � ��������� �������, ��� �� ������ � ���� �������� ����� ������� ��� �� ����������, ��� � ��
�����������, ��� ����� 2 ������ ��������, �� ���� ����� ����� ��������, ��� ���� ������ �����.

������ ������ �� ������ ������� ������ � ������� �������� except (������ ���������� 10201 - 516 = 9685 �����)

select r1.departure_city, a.city
from routes1 r1, airports a --��������� ������������
group by r1.departure_city, a.city 
except
select r1.departure_city, r1.arrival_city
from routes1 r1 
group by r1.departure_city, r1.arrival_city 
order by departure_city

9685 �����.

������������ ������ ��� �������� � ���� ���� ��� ��� ������ ������ ����� ������� � � �

select r1.departure_city, a.city
from routes1 r1, airports a 
where r1.departure_city != a.city --�������� ��� ������ 
group by r1.departure_city, a.city 
--order by r1.departure_city
except
select r1.departure_city, r1.arrival_city
from routes1 r1 
--group by r1.departure_city, r1.arrival_city 
order by departure_city


9. ��������� ���������� ����� �����������, ���������� ������� �������, 
�������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� �����

������� � ������� ������� � ��� ���� � ������� 8, ������� �� �������� ������

select distinct --������� �����, ����� � ����� Group by, �� ��� ����� ����� �������� ����������� 
	f.departure_airport, dep.city AS departure_city, dep.latitude, dep.longitude, 
	f.arrival_airport, arr.city AS arrival_city, arr.latitude, arr.longitude, --������� ������ �������, ������ ����� ������
	acos(sind(dep.latitude) * sind(arr.latitude) + 
	cosd(dep.latitude) * cosd(arr.latitude) * cosd(dep.longitude - arr.longitude)) * 6371 --6371 - ������ �����
	as distance, -- ����������
	a2."range" 
from flights f, aircrafts a2, airports dep, airports arr --2 ���� ������������ ������� ���������� (������ � �����) 
where f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code --������� ����������
and a2.aircraft_code = f.aircraft_code

�� ��� ����� �������� �������� ��� ������ ��������:

select distinct --������� �����, ����� � ����� Group by, �� ��� ����� ����� �������� ����������� 
	f.departure_airport, dep.city AS departure_city, 
	f.arrival_airport, arr.city AS arrival_city, --������� ������ �������, ������ ����� ������
	round(acos(sind(dep.latitude) * sind(arr.latitude) + 
	cosd(dep.latitude) * cosd(arr.latitude) * cosd(dep.longitude - arr.longitude)) * 6371) --6371 - ������ �����
	as distance, -- ����������
	a2."range" 
from flights f, aircrafts a2, airports dep, airports arr --2 ���� ������������ ������� ���������� (������ � �����) 
where f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code --������� ����������
and a2.aircraft_code = f.aircraft_code
order by distance desc --�����������, ��������, �� ��������� �� �������

