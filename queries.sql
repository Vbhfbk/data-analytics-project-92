--подсчитываем общее количество покупателей из таблицы customers, присваиваем столбцу имя customers_count
select COUNT(*) as customers_count 
from customers;

--выявляем 10 лучших продавцов по объёму выручки
select
	concat(e.first_name,' ',e.last_name) as seller, --имя и фамилия продавца
	COUNT(s.sales_id) as operations, --количество проведенных сделок
	FLOOR(SUM(s.quantity * p.price)) as income --суммарная выручка продавца за все время
from sales s
left join employees e
	on s.sales_person_id = e.employee_id
left join products p
	on s.product_id = p.product_id
group by 1
order by 3 desc
limit 10;

--выявляем продавцов, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
with total_average_income as (
select AVG(s.quantity * p.price)
from sales s
left join products p
	on s.product_id = p.product_id
) --где total_average_income средняя выручка за сделку по всем продавцам
select
	concat(e.first_name,' ',e.last_name) as seller, --имя и фамилия продавца
	FLOOR(AVG(s.quantity * p.price)) as average_income --средняя выручка продавца за сделку с округлением до целого
from sales s
left join employees e
	on s.sales_person_id = e.employee_id
left join products p
	on s.product_id = p.product_id
group by 1
having FLOOR(AVG(s.quantity * p.price)) < (select * from total_average_income) --средняя выручка за сделку продавца меньше средней выручки за сделку по всем продавцам
order by 2;

--получаем информацию о выручке по дням недели для каждого продавца
with ranged_data as (
select
	concat(e.first_name,' ',e.last_name) as seller, --имя и фамилия продавца
	to_char(s.sale_date, 'Day') as day_of_week, -- название дня недели на английском языке
	FLOOR(AVG(s.quantity * p.price)) as income, --суммарная выручка продавца в определенный день недели, округленная до целого числа
	extract(ISODOW from s.sale_date) as number_of_day --порядковый номер дня в неделе
from sales s
left join employees e
	on s.sales_person_id = e.employee_id
left join products p
	on s.product_id = p.product_id
group by 1, 2, 4
order by 4, 1 --сортируем данные по порядковому номеру дня в неделе и seller
) -- где ranged_data данные по выручке ранжированные по порядковому номеру дня недели и имени продавца
select 
	seller, --имя и фамилия продавца
	day_of_week, -- название дня недели на английском языке
	income --суммарная выручка продавца в определенный день недели, округленная до целого числа
from ranged_data;