-- How many pizzas were ordered?

select count(order_id) as total_pizza
from orders_staging;

-- How many unique customer orders were made?

select count(distinct(order_id)) as unique_customer_orders
from orders_staging;

-- How many successful orders were delivered by each runner?

select runner_id, count(order_id) as successful_orders
from runner_order2
where cancellation is null
group by runner_id;

-- How many of each type of pizza was delivered?

select pizza_id, count(pizza_id) as total
from orders_staging os
join runner_order2 ro on os.order_id = ro.order_id
where cancellation is null
group by pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?

select customer_id, pizza_name, count(os.pizza_id)
from orders_staging os
join pizza_names pn on os.pizza_id = pn.pizza_id
group by customer_id, pizza_name
order by customer_id;

-- What was the maximum number of pizzas delivered in a single order?

select order_id, count(pizza_id) as total
from orders_staging
group by order_id
order by total desc
limit 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select customer_id, 
count(
case
when exclusions is not null or extras is not null then 1
end
) as changed,
count(
case
when exclusions is null and extras is null then 1
end
) as not_changed
from orders_staging os
join runner_order2 ro on os.order_id = ro.order_id
where cancellation is null
group by customer_id
order by customer_id;

-- How many pizzas were delivered that had both exclusions and extras?

select count(pizza_id) as total
from delivered_orders
where exclusions is not null and extras is not null;

-- What was the total volume of pizzas ordered for each hour of the day?

select extract(hour from order_time)as hour_day, count(pizza_id) as volume_pizza
from orders_staging
group by hour_day
order by hour_day;

-- What was the volume of orders for each day of the week?

with volume_of_orders as (select weekday(order_time) as day_of_week, count(pizza_id) as volume_pizza
from orders_staging
group by day_of_week
order by day_of_week)

select
case
when day_of_week = 0 then 'Monday'
when day_of_week = 1 then 'Tuesday'
when day_of_week = 2 then 'Wednesday'
when day_of_week = 3 then 'Thursday'
when day_of_week = 4 then 'Friday'
when day_of_week = 5 then 'Saturday'
when day_of_week = 6 then 'Sunday'
end as week_day,
volume_pizza
from volume_of_orders;