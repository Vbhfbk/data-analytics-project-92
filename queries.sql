--подсчитываем общее количество покупателей из таблицы customers
select COUNT(*) as customers_count
from customers;

--выявляем 10 лучших продавцов по объёму выручки
select
    CONCAT(e.first_name, ' ', e.last_name) as seller, --имя и фамилия продавца
    COUNT(s.sales_id) as operations, --количество проведенных сделок
    FLOOR(SUM(s.quantity * p.price)) as income --суммарная выручка продавца
from sales s
left join employees e
    on s.sales_person_id = e.employee_id
left join products p
    on s.product_id = p.product_id
group by 1
order by 3 desc
limit 10;

--выявляем продавцов, чья средняя выручка за сделку меньше средней по компании
with total_average_income as (
    select AVG(s.quantity * p.price) as avg_income
    from sales s
    left join products p
        on s.product_id = p.product_id
) --где total_average_income средняя выручка за сделку по всем продавцам

select
    CONCAT(e.first_name, ' ', e.last_name) as seller, --имя и фамилия продавца
    FLOOR(AVG(s.quantity * p.price)) as average_income --средняя выручка за сделку
from sales s
left join employees e
    on s.sales_person_id = e.employee_id
left join products p
    on s.product_id = p.product_id
group by 1
having FLOOR(AVG(s.quantity * p.price)) < (select total_average_income.avg_income from total_average_income)
--средняя выручка за сделку продавца меньше средней выручки за сделку по всем продавцам
order by 2;

--получаем информацию о выручке по дням недели
with ranged_data as (
    select
        CONCAT(e.first_name, ' ', e.last_name) as seller, --имя и фамилия продавца
        TO_CHAR(s.sale_date, 'day') as day_of_week, -- название дня недели на английском языке
        FLOOR(SUM(s.quantity * p.price)) as income, --суммарная выручка продавца в определенный день недели
        EXTRACT(isodow from s.sale_date) as number_of_day --порядковый номер дня в неделе
    from sales s
    left join employees e
        on s.sales_person_id = e.employee_id
    left join products p
        on s.product_id = p.product_id
    group by 1, 2, 4
    order by 4, 1 --сортируем данные по порядковому номеру дня в неделе и seller
) --данные по выручке ранжированные по порядковому номеру дня недели и имени продавца

select
    seller, --имя и фамилия продавца
    day_of_week, -- название дня недели на английском языке
    income --суммарная выручка продавца в определенный день недели, округленная до целого числа
from ranged_data;

--считаем количество покупателей в возрастных группах: 16-25, 26-40 и 40+
select
    (case
        when age >= 16 and age <= 25 then '16-25'
        when age >= 26 and age <= 40 then '26-40'
	else '40+'
    end) as age_category, --возрастная группа
    COUNT(*) as age_count --количество человек в группе
from customers
group by 1
order by 1; --сортируем данные по age_category

--считаем данные по количеству уникальных покупателей и выручке 
select
    TO_CHAR(s.sale_date, 'YYYY-MM') as selling_month, --дата
    COUNT(distinct s.customer_id) as total_customers, --количество покупателей
    FLOOR(SUM(p.price * s.quantity)) as income -- выручка
from sales s
left join customers c
    on s.customer_id = c.customer_id
left join products p
    on s.product_id = p.product_id
group by 1 --группируем данные по дате
order by 1; --сортируем данные по дате по возрастанию 

--данные покупателей, первая покупка которых была в ходе проведения акций
with tab as (
    select
        s.sale_date,
        p.price, --цена товара в покупке
        s.customer_id,
	CONCAT(c.first_name, ' ', c.last_name) as customer,
        CONCAT(e.first_name, ' ', e.last_name) as seller,
        ROW_NUMBER() OVER (partition by CONCAT(c.first_name, ' ', c.last_name) order by s.sale_date, s.sales_id) as sales_number
    --порядковый номер покупки для конкретного покупателя, дополнительное ранжирование по sales_id для выявления первой покупки в рамках дня
    from sales s
    left join customers c
        on s.customer_id = c.customer_id
    left join products p
        on s.product_id = p.product_id
    left join employees e
        on s.sales_person_id = e.employee_id
    where p.price = 0
)

select
    customer, --имя и фамилия покупателя
    sale_date, --дата покупки
    seller --имя и фамилия продавца
from tab
where sales_number = 1
order by customer_id;
