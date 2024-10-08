SELECT * FROM pizzahut.pizzas;
create table orders(
order_id int not null,
order_date date not null,
order_time time not null,
primary key (order_id) );

create table order_details(
order_details_id int primary key not null,
order_id int not null,
pizza_id varchar(30) not null,
quantity int not null);

-- Basic

# 1-- Retrieve the total number of orders placed
select count(order_id) as Total_Orders
from orders;

# 2-- Calculate the total revenue generated from pizza sales.
select
round(sum(o.quantity*p.price),2) as Total_Revenue
from order_details o
join pizzas p
on o.pizza_id=p.pizza_id;

# 3-- Identify the highest-priced pizza.
select t.name, p.price as Highest_Price
from pizza_types t join pizzas p
on p.pizza_type_id=t.pizza_type_id
order by p.price desc limit 1;

# 4-- Identify the most common pizza size ordered.
select p.size, sum(od.quantity) as quantity
from order_details od join pizzas p
on od.pizza_id=p.pizza_id
group by P.Size
order by quantity desc
limit 1;

# 5-- List the top 5 most ordered pizza types along with their quantities.
select pt.name, sum(od.quantity) as quantity
from order_details od
inner join pizzas p on od.pizza_id=p.pizza_id
inner join pizza_types pt on p.pizza_type_id=pt.pizza_type_id
group by name
order by quantity desc
limit 5;

-- Intermediate

# 6-- Join the necessary tables to find the total quantity of each pizza category ordered.
select pt.category, sum(od.quantity) as quantity 
from order_details od
inner join pizzas p on p.pizza_id=od.pizza_id
inner join pizza_types pt on pt.pizza_type_id=p.pizza_type_id
group by category;

# 7-- Determine the distribution of orders by hour of the day.
select hour(order_time) as hour, count(order_id) as order_count
from orders
group by hour;

# 8-- Join relevant tables to find the category-wise distribution of pizzas.
select pt.category, count(od.order_details_id) as distribution
from order_details od
join pizzas p on p.pizza_id=od.pizza_id
join pizza_types pt on p.pizza_type_id=pt.pizza_type_id
group by category;

## 9-- Group the orders by date and calculate the average number of pizzas ordered per day.
select round(avg(quantity),0) from
(select o.order_date, sum(od.quantity) as quantity
from orders o join order_details od
on o.order_id=od.order_id
group by order_date) as order_quantity;

## 10-- Determine the top 3 most ordered pizza types based on revenue.
select pt.name, sum(p.price*od.quantity) as Revenue, sum(od.quantity) as orders
from order_details od
join pizzas p on od.pizza_id=p.pizza_id
join pizza_types pt on p.pizza_type_id=pt.pizza_type_id
group by name
order by Revenue desc
limit 3;

## 11-- Calculate the percentage contribution of each pizza type to total revenue.
select pt.category,
round(sum(od.quantity*p.price) / (select round(sum(od.quantity*p.price),2) as total_sales
from order_details od join pizzas on od.pizza_id=p.pizza_id) *100,2) as Revenue
from pizza_types pt
join pizzas p on pt.pizza_type_id=p.pizza_type_id
join order_details od on od.pizza_id=p.pizza_id
group by pt.category order by revenue desc limit 1;

-- The above query is taking so much time to run so below used CTE(Common Table Expression) to run it 

WITH total_sales AS (
    SELECT ROUND(SUM(od.quantity * p.price), 2) AS total_sales
    FROM order_details od
    JOIN pizzas p ON od.pizza_id = p.pizza_id
)
SELECT pt.category,
       ROUND(SUM(od.quantity * p.price) / (SELECT total_sales FROM total_sales) * 100, 2) AS Revenue
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY Revenue desc;

# 12-- Analyze the cumulative revenue generated over time.
select order_date,
sum(revenue) over (order by order_date) as cum_revenue
from
(select o.order_date, sum(od.quantity*p.price) as revenue
from orders o
join order_details od on o.order_id=od.order_id
join pizzas p on od.pizza_id=p.pizza_id
group by order_date) as sales;

# 13-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select name, revenue from
(select category, name, revenue,
rank() over(partition by category order by revenue desc) as rn
from
(select pizza_types.category, pizza_types.name, sum((order_details.quantity)*pizzas.price) as revenue
from pizza_types
join pizzas on pizza_types.pizza_type_id=pizzas.pizza_type_id
join order_details on order_details.pizza_id=pizzas.pizza_id
group by pizza_types.category, pizza_types.name) as a) as b
where rn<=3;
