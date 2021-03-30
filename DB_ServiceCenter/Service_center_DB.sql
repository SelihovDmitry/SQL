-- Описание БД тут https://docs.google.com/document/d/1LDYrqQ810SOmDVQUvY9CeQkyGCHcbOk6iYlhQZIJu8E/edit?usp=sharing

create schema service_center;

--Таблица сотрудников
create table staff (
	staff_id serial primary key,
	first_name varchar(30) not null,
	last_name varchar(50) not null,
	age integer not null,
	position varchar(50) not null
)

drop table staff

insert into staff(first_name, last_name, age, position)
values
	('Dmitry','Selikhov',37,'Engineer'),
	('Timofey','Ivanov',42,'Lead Engineer'),
	('Andrey','Baranov',32,'Engineer'),
	('Dmitry','Smirnov',48,'Head of Department'),
	('Alexandra','Kurnikova', 27,'Manager'),
	('Aleksey','Khohlov',29,'Engineer')
	
select * from staff
	
-- Таблица клиентов
create table customer (
	customer_id serial primary key,
	name varchar(50) not null,
	inn varchar(20) not null unique,
	phone varchar(50) not null,
	e_mail varchar(100),
	contact varchar(50)
)

-- drop table customer

insert into customer(name, inn, phone, e_mail, contact)
values
	('ООО Внедренческий центр', '7710267450', '253-03-04', 'afanad@parus1.ru', 'Надежда'),
	('ООО Компания АрмИТ', '7718264735', '+7 495 568-32-66 доб 99', 'warranty@amr-it.ru', 'Андрей'),
	('ИП Плюшкин', '456578951235', '8-916-456-67-78', 'plyushkin@mail.ru', 'Иннокентий'),
	('ООО Рога и Копыта', '7712436589', '2-15-33', 'roga_i_kopyta@gmail.com', 'Зицпредседатель Фунт')
	
select * from customer
	
--таблица оборудования
create table device (
	device_id serial primary key,
	dev_name varchar(255) not null unique
)

-- drop table device

insert into device(dev_name)
values
	('Штрих-ФР-01Ф'),
	('Штрих-ФР-02Ф'),
	('Штрих-Лайт-01Ф'),
	('Штрих-Online'),
	('Элвес-ФР-Ф'),
	('Штрих-Принт')

--таблица запчастей
create table repair_parts (
	part_number varchar(20) primary key,
	part_name varchar(255) not null unique,
	price decimal(10,2) not null,
	quantity int2 not null
)

 drop table repair_parts

insert into repair_parts(part_number, part_name, price, quantity)
values
	('K123', 'Термоголовка', 1500, 20),
	('K101', 'Системная плата', 2500, 10),
	('K102', 'Модуль Wi-Fi', 1300, 40),
	('S123', 'Дисплей', 3500, 15)
	
insert into repair_parts(part_number, part_name, price, quantity)
values
	('K103', 'Блок питания', 700, 20)	

select * from repair_parts

--таблица ремонтов
create table repairs (
	repair_id serial primary key,
	date_in timestamp not null default now(),
	device_id int references device(device_id),
	customer_id int references customer(customer_id),
	staff_id int references staff(staff_id),
	description text,
	cost decimal(10,2),
	date_out timestamp,
	status varchar(50) not null default 'Принято в ремонт'
)

--drop table repairs

insert into repairs (device_id, customer_id, staff_id, description)
values
	(4, 1, 6, 'Доработка до Wi-Fi'),
	(2, 2, 1, 'Нет печати'),
	(3, 3, 2, 'Не включается'),
	(6, 4, 3, 'Разбит дисплей')

update repairs
set cost = 2500,
	date_out = now()::date,
	status = 'Ремонт завершен'
where repair_id = 1

update repairs
set cost = 4500,
	date_out = now()::date,
	description = 'Не включается: замена системной платы и блока питания',
	status = 'Оборудование выдано'
where repair_id = 3
	
select * from repairs

--таблица связей ремонтов и запчастей
create table repairs_repair_parts (
	repair_id int references repairs(repair_id),
	repair_part varchar(20) references repair_parts(part_number),
	CONSTRAINT repair_repair_part PRIMARY KEY (repair_id, repair_part)
)

--drop table repairs_repair_parts

insert into repairs_repair_parts (repair_id, repair_part)
values
	(1, 'K102'),
	(2, 'K101'),
	(2, 'K103')

select * from repairs_repair_parts

Можно напрмиер вывести итоговую стоимость ремонта на каждого сотрудника:

select s.last_name || s.first_name as name, sum("cost") 
from repairs r
join staff s on r.staff_id = s.staff_id 
group by s.staff_id 

или вывести все запчасти которые были использованы в ремонте № 2:

select rrp.repair_id, rrp.repair_part, rp.part_name 
from repairs_repair_parts rrp
left join repair_parts rp on rp.part_number = rrp.repair_part 
where repair_id = 2