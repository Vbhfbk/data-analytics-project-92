--подсчитываем общее количество покупателей из таблицы customers
select COUNT(*) as customers_count
from customers;

--выявляем 10 лучших продавцов по объёму выручки
select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    COUNT(s.sales_id) as operations,
    FLOOR(SUM(s.quantity * p.price)) as income
from sales s
left join employees e
    on s.sales_person_id = e.employee_id
left join products p
    on s.product_id = p.product_id
group by 1
order by 3 desc
limit 10;

--выявляем продавцов, чья средняя выручка за сделку меньше средней
with total_average_income as (
    select AVG(s.quantity * p.price) as avg_income
    from sales s
    left join products p
        on s.product_id = p.product_id
)

select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    FLOOR(AVG(s.quantity * p.price)) as average_income
from sales s
left join employees e
    on s.sales_person_id = e.employee_id
left join products p
    on s.product_id = p.product_id
group by 1
having FLOOR(AVG(s.quantity * p.price)) < 
(select total_average_income.avg_income from total_average_income)
order by 2;

--получаем информацию о выручке по дням недели
with ranged_data as (
    select
        CONCAT(e.first_name, ' ', e.last_name) as seller,
        TO_CHAR(s.sale_date, 'day') as day_of_week,
        FLOOR(SUM(s.quantity * p.price)) as income,
        EXTRACT(isodow from s.sale_date) as number_of_day
    from sales s
    left join employees e
        on s.sales_person_id = e.employee_id
    left join products p
        on s.product_id = p.product_id
    group by 1, 2, 4
    order by 4, 1
)

select
    seller,
    day_of_week,
    income
from ranged_data;

--считаем количество покупателей в возрастных группах: 16-25, 26-40 и 40+
select
    (case
        when c.age >= 16 and c.age <= 25 then '16-25'
        when c.age >= 26 and c.age <= 40 then '26-40'
	else '40+'
    end) as age_category,
    COUNT(*) as age_count
from customers c
group by 1
order by 1;

--считаем данные по количеству уникальных покупателей и выручке 
select
    TO_CHAR(s.sale_date, 'YYYY-MM') as selling_month,
    COUNT(distinct s.customer_id) as total_customers,
    FLOOR(SUM(p.price * s.quantity)) as income
from sales s
left join products p
    on s.product_id = p.product_id
group by 1
order by 1;

--данные покупателей, первая покупка которых была в ходе проведения акций
with tab as (
    select
        s.sale_date,
        p.price,
        s.customer_id,
	CONCAT(c.first_name, ' ', c.last_name) as customer,
        CONCAT(e.first_name, ' ', e.last_name) as seller,
        ROW_NUMBER() OVER (PARTITION by CONCAT(c.first_name, ' ', c.last_name) 
	order by s.sale_date, s.sales_id) as sales_number
    from sales s 
    left join customers c
        on s.customer_id = c.customer_id
    left join products p
        on s.product_id = p.product_id
    left join employees e
        on s.sales_person_id = e.employee_id
    where p.price = 0
    order by s.customer_id
)
	
select
    customer,
    sale_date,
    seller
from tab
where sales_number = 1;
