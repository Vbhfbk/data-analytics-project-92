--подсчитываем общее количество покупателей из таблицы customers
select COUNT(*) as customers_count
from customers;

--выявляем 10 лучших продавцов по объёму выручки
select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    COUNT(s.sales_id) as operations,
    FLOOR(SUM(s.quantity * p.price)) as income
from sales as s
left join employees as e
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id
group by 1
order by 3 desc
limit 10;

--выявляем продавцов, чья средняя выручка за сделку меньше средней
select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    FLOOR(AVG(s.quantity * p.price)) as average_income
from sales as s
left join employees as e
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id
group by 1
having
    FLOOR(AVG(s.quantity * p.price))
    < (select AVG(sl.quantity * pr.price) as avg_income
    from sales as sl
    left join products as pr
        on sl.product_id = pr.product_id
    )
order by 2;

--получаем информацию о выручке по дням недели
select
    CONCAT(e.first_name, ' ', e.last_name) as seller,
    TO_CHAR(s.sale_date, 'day') as day_of_week,
    FLOOR(SUM(s.quantity * p.price)) as income
from sales as s
left join employees as e
    on s.sales_person_id = e.employee_id
left join products as p
    on s.product_id = p.product_id
group by CONCAT(e.first_name, ' ', e.last_name), TO_CHAR(s.sale_date, 'day'), EXTRACT(isodow from s.sale_date)
order by EXTRACT(isodow from s.sale_date), CONCAT(e.first_name, ' ', e.last_name);

--считаем количество покупателей в возрастных группах: 16-25, 26-40 и 40+
select
    (case
        when c.age between 16 and 25 then '16-25'
        when c.age between 26 and 40 then '26-40'
        else '40+'
    end) as age_category,
    COUNT(*) as age_count
from customers as c
group by 1
order by 1;

--считаем данные по количеству уникальных покупателей и выручке 
select
    TO_CHAR(s.sale_date, 'YYYY-MM') as selling_month,
    COUNT(distinct s.customer_id) as total_customers,
    FLOOR(SUM(p.price * s.quantity)) as income
from sales as s
left join products as p
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
        ROW_NUMBER() over (
            partition by CONCAT(c.first_name, ' ', c.last_name)
            order by s.sale_date
        ) as sales_number
    from sales as s
    left join customers as c
        on s.customer_id = c.customer_id
    left join products as p
        on s.product_id = p.product_id
    left join employees as e
        on s.sales_person_id = e.employee_id
    where p.price = 0
    order by 3
)

select
    customer,
    sale_date,
    seller
from tab
where sales_number = 1;
