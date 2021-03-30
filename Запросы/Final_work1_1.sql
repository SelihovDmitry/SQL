 1. В каких городах больше одного аэропорта?
 
 select city, count(airport_code) as cnt --выбираем города и количество аэропортов
 from airports
 group by city --надо использовать group by т.к. использовалась агрегатная функция
 having count(airport_code) > 1 --оставляем те, где количество больше 1
 order by cnt --сортируем
 
 
  2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
 
 
 Первый вариант
 
 /*
  * Сразу понятно что нам понадобится 3 таблицы: aircrafts - чтобы взять оттуда максимальную дальность,
  * airports, т.к. надо вывести название аэропорта и таблицу flights для связи между ними.
  */
 select a.airport_name, a2.model, range --выбираем нужные столбцы для вывода
 from airports a 
 join flights f on a.airport_code = f.departure_airport -- тут я считаю неважно к какому атрибуту таблицы flights 
 -- делать join departure_airport или arrival_airport, т.к. в общем случае если самолет прилетел, то он и улетит и наоборот
 join aircrafts a2 on f.aircraft_code = a2.aircraft_code 
 where "range" = (select max(a2."range") from aircrafts a2) -- оставляем среди этого рейсы, выполняемые самолетом с максимальной
 group by a.airport_name, a2.model, range -- группируем
 -- но мне кажется этот запрос не оптимальный, т.к. мы формируем таблицу со всеми данными и оттуда уже вычленыем нужные нам
 
 
 второй вариант
 
 select a.airport_name, mr.model, range
 from (
 	select a2.aircraft_code, a2.model, a2."range" 
	from aircrafts a2 
	where "range" = (select max(a2."range") from aircrafts a2)
 	) as mr -- выделяем сомолет с самой большой дальностью
 left join flights f on f.aircraft_code = mr.aircraft_code
 left join airports a on f.departure_airport = a.airport_code 
 group by a.airport_name, mr.model, range
 -- работает вроде быстрее чем первый, т.к. условие where делаем для "маленькой" таблицы 
 -- и потом мы присоединяем только нужные данные
 
 
  3. Вывести 10 рейсов с максимальным временем задержки вылета
 
 select flight_id, flight_no, scheduled_departure, actual_departure, 
 	(actual_departure - scheduled_departure) as delay
 from flights -- выводим значимую информацию по рейсу и время задержки
 where actual_departure is not null -- убираем null значения (например если самолет еще не вылетел, то actual_departure будет null)
 order by delay desc --сортируем по убыванию
 limit 10 -- оставляем первые 10
 
 
 4. Были ли брони, по которым не были получены посадочные талоны?

select b.book_ref, bp.ticket_no 
from bookings b
left join tickets t on t.book_ref = b.book_ref
left join boarding_passes bp on t.ticket_no = bp.ticket_no --делаем именно left join, т.к. надо оставить полностью таблицу
--билетов и к ним присоединить посадочные талоны
where bp.ticket_no is null --если у билета нет талона, то ticket_no из табилцы талонов будет null, они нам и нужны
--group by b.book_ref, bp.ticket_no --оставляем уникальные бронирования, но это увеличивает время запроса 5 раз,
--т.е. исходя из условий задачи (нужет ответ ДА или НЕТ), эту группировку можно не использовать. Такие брони БЫЛИ.
 

5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное количество вывезенных пассажиров из аэропорта за день. 
Т.е. в этом столбце должна отражаться сумма - сколько человек уже вылетело из данного аэропорта на 
этом или более ранних рейсах за сегодняшний день

select f.flight_id, f.flight_no, f.aircraft_code, allst.allseats, count(bp.seat_no) as busy_seats, --выбираем столбцы для вывода
	allst.allseats - count(bp.seat_no) as free_seats, -- считаем число свободных мест, count(bp.seat_no) - число занятых мест в рейсе
	round(((allst.allseats - count(bp.seat_no))::numeric(5,2) / allst.allseats), 4)*100 as percent_free, -- считаем процент
	--приводим к numeric чтобы деление было дробным, с помощью round оставляем точность до сотых долей процента
	f.actual_departure::date, --приводим к дате, без времени и секунд
	f.departure_airport,
	a2.airport_name, 
	sum(count(bp.seat_no)) over(partition by f.actual_departure::date, f.departure_airport order by f.actual_departure, f.departure_airport)
		as depart_people -- используем order by, без нее в оконной функции в каждой строке выводилась сумма за день, а не накопление
		--в качестве окна выделяем дату, чтобы она была одинаковая, приводим к дате, без часов, мин, сек.
from flights f
left join airports a2 on f.departure_airport = a2.airport_code --добавляем чтобы вывести название аэропорта
left join ticket_flights tf using(flight_id) --промежуточная таблица чтобы добраться до boarding_passes
left join boarding_passes bp using(ticket_no, flight_id) --присоединяем чтобы понять сколько мест в рейсе занято
join (select s.aircraft_code, count(s.seat_no) as allseats
		from seats s
		group by s.aircraft_code) as allst on f.aircraft_code = allst.aircraft_code --к этому тоже не сразу пришел, присоединяем таблицу
		--с максимальной вместимостью самолетов, можно наверное и по другому сделать, но у меня так получилось
group by f.flight_id, f.flight_no, f.aircraft_code, allst.allseats, a2.airport_name --группировка, чтобы сработала функция count(bp.seat_no)
--p.s. запрос выполняется довольно долго, 3.5 - 4 сек. Наверное можно как-то оптимизировать,
--p.p.s я писал этот запрос часа 3.


6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.

/*
 * Нам надо поделить кол-во перелетов с каждым типом самолета на общее кол-во перелетов
 * всего у нас 8 типов самолетов, значит в результирующей таблице должно получиться 8 строк
 * причем сумма значений будет равняться 100
 * в подзапросе считаем общее кол-во перелетов
 */

select aircraft_code, 
	round(count(aircraft_code)::numeric(10,2) / 
		(select count(flight_id) from flights f2 ), 4)*100 as percent_aircraft
from flights f
group by aircraft_code

--проверим, действительно ли получается 100
with cte_1 as 
(
	select aircraft_code, 
		round(count(aircraft_code)::numeric(10,2) / 
			(select count(flight_id) from flights f2 ), 4)*100 as percent_aircraft
	from flights f
	group by aircraft_code
)
select sum(cte_1.percent_aircraft) from cte_1
-- все верно, погрешность в 0.01 из-за округления.


7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

with amount_business as --создаем табличку с ценами на бизнес класс 
(
	select tf.amount as business, tf.fare_conditions, tf.flight_id, tf.ticket_no 
	from ticket_flights tf 
	where fare_conditions = 'Business'
)
select amount_business.business, amount_economy.economy 
from amount_business
join ( --присоединяе к ней по flyght_id таблицку с ценами на Эконом класс
		select flight_id, amount as economy
		from ticket_flights
		where fare_conditions = 'Economy'
	) amount_economy on amount_business.flight_id = amount_economy.flight_id
where amount_business.business < amount_economy.economy --прописываем условие задачи - если бизнес дешевле эконома
--ТАКИХ ПЕРЕЛЕТОВ, А СООТВ. И ГОРОДОВ НЕТ. Если бы они были то можно присоединить таблицы
--flights и airports (2 раза - нужен город вылета и город прилета) для вывода городов откуда и куда рейс.

ну давайте сделаем (присоединим города вылета и прилета) это для наглядности и практики,
условие можно поменять с < на > и таблица заполнится.

with amount_business as
(
select tf.flight_id, tf.fare_conditions, tf.amount as amount_business, dep.city as from, arr.city as to
from ticket_flights tf, flights f, airports arr, airports dep
where f.flight_id = tf.flight_id
	and f.departure_airport = dep.airport_code 
	and f.arrival_airport = arr.airport_code
	and tf.fare_conditions = 'Business'
) --также создаем табличку с ценами на бизнес класс но с городами вылета и прилета 
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
		--также присоединяе к ней по flyght_id таблицку с ценами на Эконом класс но с городами вылета и прилета
where amount_business.amount_business < amount_economy.amount_economy --то же если бизнес дешевле эконома, то эта разница будет положительной
group by amount_business.flight_id, 
	amount_business.amount_business, amount_economy.amount_economy,
	amount_business.from, amount_business.to  
	--но опять же ответ на поставленный в задаче вопрос в запросе выше, т.е. таких городов нет, следовательно join'ить
	--таблицы для их вывода излишле. Это с одной стороны, с другой такие рейсы могут появиться и второй запрос будет более универсальным.
	
Т.е. в итоге задачу я свел к тому чтобы создать 2 таблички с ценами на эконом и бизнес и в уловии прописываем 
что цена за бизнес меньше чем за эконом


8. Между какими городами нет прямых рейсов?
- Декартово произведение в предложении FROM
- Представления
- Оператор except

Некоторое предисловие для дальнейшей проверки результата.

Мы полагаем что если из какого-то аэропорта есть вылеты в определенный город, то есть и прилеты оттуда

всего аэропортов у нас:

select count(city) from airports a --104

но из задания мы 1 помним что в Ульяновске 2 аэропорта, а в Москве 3, т.е. городов всего 104 - 3 = 101
Т.е. всего связей городов должно быть 101 * 101 = 10201.
Выведем все эти связи, для этого сначала создадим предстваление где будут указаны города вылета и прилета исходя из аэропортов:

create or replace view routes1 
as select f.departure_airport, dep.city AS departure_city,
	f.arrival_airport, arr.city AS arrival_city
from flights f, airports dep, airports arr --соединяем 2 раза с таблицей аэропортов (через аэропорт вылета и прилета), из нее берем город
where f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code;

select * from routes1 r

Таблица со всеми возможными связями городов, где есть аэропорты (декартово произведение)

select r1.departure_city, a.city
from routes1 r1, airports a --декартово произведение
group by r1.departure_city, a.city 
order by r1.departure_city

Получилось 10201 строка, как мы и полагали. Ну тут есть некая аномалия, в виде того что нельзя улететь из города А в него же самого,
в точки зрения ПК - это логично, с человеческой точки зрения - я бы эти строки удалил, 
т.к. и так понятно что нет прямых рейсов из Абакана в Абакан итп., но не очень понимаю как и можно ли это средствами Postgre.

Таблица в возможными перелетами:

select r1.departure_city, r1.arrival_city
from routes1 r1 
group by r1.departure_city, r1.arrival_city 
order by r1.departure_city

516 строк - 516 разных вариантов маршрутов, а точнее городов, между которыми есть прямые рейсы, маршрутов может быть больше
из за нескольких аэропортов в некоторых городах, так из Москвы в Сочи наверное можно улететь как из Домодедово, так и из
Шереметьево, это будет 2 разных маршрута, но одна связь между городами, где есть прямые рейсы.

Теперь вычтем из первой таблицы вторую с помощью оператоа except (должно получиться 10201 - 516 = 9685 строк)

select r1.departure_city, a.city
from routes1 r1, airports a --декартово произведение
group by r1.departure_city, a.city 
except
select r1.departure_city, r1.arrival_city
from routes1 r1 
group by r1.departure_city, r1.arrival_city 
order by departure_city

9685 строк.

Исправленный запрос без аномалий в виде того что нет прямых рейсов между городом А и А

select r1.departure_city, a.city
from routes1 r1, airports a 
where r1.departure_city != a.city --добавили эту строку 
group by r1.departure_city, a.city 
--order by r1.departure_city
except
select r1.departure_city, r1.arrival_city
from routes1 r1 
--group by r1.departure_city, r1.arrival_city 
order by departure_city


9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы

Таблица с прямыми рейсами у нас была в задании 8, возьмем по аналогии оттуда

select distinct --убираем дубли, можно и через Group by, но там много всего придется перечислять 
	f.departure_airport, dep.city AS departure_city, dep.latitude, dep.longitude, 
	f.arrival_airport, arr.city AS arrival_city, arr.latitude, arr.longitude, --выводим нужные столбцы, лишние можно убрать
	acos(sind(dep.latitude) * sind(arr.latitude) + 
	cosd(dep.latitude) * cosd(arr.latitude) * cosd(dep.longitude - arr.longitude)) * 6371 --6371 - радиус земли
	as distance, -- расстояние
	a2."range" 
from flights f, aircrafts a2, airports dep, airports arr --2 раза присоединяем таблицу аэропортом (прилет и вылет) 
where f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code --условие соединения
and a2.aircraft_code = f.aircraft_code

Ну или более красивая табличка без лишних столбцов:

select distinct --убираем дубли, можно и через Group by, но там много всего придется перечислять 
	f.departure_airport, dep.city AS departure_city, 
	f.arrival_airport, arr.city AS arrival_city, --выводим нужные столбцы, лишние можно убрать
	round(acos(sind(dep.latitude) * sind(arr.latitude) + 
	cosd(dep.latitude) * cosd(arr.latitude) * cosd(dep.longitude - arr.longitude)) * 6371) --6371 - радиус земли
	as distance, -- расстояние
	a2."range" 
from flights f, aircrafts a2, airports dep, airports arr --2 раза присоединяем таблицу аэропортом (прилет и вылет) 
where f.departure_airport = dep.airport_code AND f.arrival_airport = arr.airport_code --условие соединения
and a2.aircraft_code = f.aircraft_code
order by distance desc --отсортируем, например, по дальности по убываню

