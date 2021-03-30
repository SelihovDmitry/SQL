-- �������� �� ��� https://docs.google.com/document/d/1LDYrqQ810SOmDVQUvY9CeQkyGCHcbOk6iYlhQZIJu8E/edit?usp=sharing

create schema service_center;

--������� �����������
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
	
-- ������� ��������
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
	('��� ������������� �����', '7710267450', '253-03-04', 'afanad@parus1.ru', '�������'),
	('��� �������� �����', '7718264735', '+7 495 568-32-66 ��� 99', 'warranty@amr-it.ru', '������'),
	('�� �������', '456578951235', '8-916-456-67-78', 'plyushkin@mail.ru', '����������'),
	('��� ���� � ������', '7712436589', '2-15-33', 'roga_i_kopyta@gmail.com', '��������������� ����')
	
select * from customer
	
--������� ������������
create table device (
	device_id serial primary key,
	dev_name varchar(255) not null unique
)

-- drop table device

insert into device(dev_name)
values
	('�����-��-01�'),
	('�����-��-02�'),
	('�����-����-01�'),
	('�����-Online'),
	('�����-��-�'),
	('�����-�����')

--������� ���������
create table repair_parts (
	part_number varchar(20) primary key,
	part_name varchar(255) not null unique,
	price decimal(10,2) not null,
	quantity int2 not null
)

 drop table repair_parts

insert into repair_parts(part_number, part_name, price, quantity)
values
	('K123', '������������', 1500, 20),
	('K101', '��������� �����', 2500, 10),
	('K102', '������ Wi-Fi', 1300, 40),
	('S123', '�������', 3500, 15)
	
insert into repair_parts(part_number, part_name, price, quantity)
values
	('K103', '���� �������', 700, 20)	

select * from repair_parts

--������� ��������
create table repairs (
	repair_id serial primary key,
	date_in timestamp not null default now(),
	device_id int references device(device_id),
	customer_id int references customer(customer_id),
	staff_id int references staff(staff_id),
	description text,
	cost decimal(10,2),
	date_out timestamp,
	status varchar(50) not null default '������� � ������'
)

--drop table repairs

insert into repairs (device_id, customer_id, staff_id, description)
values
	(4, 1, 6, '��������� �� Wi-Fi'),
	(2, 2, 1, '��� ������'),
	(3, 3, 2, '�� ����������'),
	(6, 4, 3, '������ �������')

update repairs
set cost = 2500,
	date_out = now()::date,
	status = '������ ��������'
where repair_id = 1

update repairs
set cost = 4500,
	date_out = now()::date,
	description = '�� ����������: ������ ��������� ����� � ����� �������',
	status = '������������ ������'
where repair_id = 3
	
select * from repairs

--������� ������ �������� � ���������
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

����� �������� ������� �������� ��������� ������� �� ������� ����������:

select s.last_name || s.first_name as name, sum("cost") 
from repairs r
join staff s on r.staff_id = s.staff_id 
group by s.staff_id 

��� ������� ��� �������� ������� ���� ������������ � ������� � 2:

select rrp.repair_id, rrp.repair_part, rp.part_name 
from repairs_repair_parts rrp
left join repair_parts rp on rp.part_number = rrp.repair_part 
where repair_id = 2