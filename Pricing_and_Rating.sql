-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

select
sum(case
when pizza_id = 1 then 12
else 10
end) as total_profit
from orders_staging;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

with cte as (select
sum(case
when pizza_id = 1 then 12
else 10
end) as pizza_total,
sum(
case
when extras is not null then 1
end) as extra_total
from orders_staging)

select pizza_total + extra_total as total_profits
from cte;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

create table runner_rating(
runner_id int, order_id int, rating int);

insert into runner_rating (runner_id, order_id, rating)
values 
(1,1,3),
(1,2,4),
(1,3,5),
(2,4,1),
(3,5,5),
(2,7,4),
(2,8,5),
(1,10,3);

select *
from runner_rating;

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id*
-- order_id*
-- runner_id*
-- rating*
-- order_time*
-- pickup_time*
-- Time between order and pickup*
-- Delivery duration*
-- Average speed*
-- Total number of pizzas*

drop view if exists sucessful_deliveries;
create view sucessful_deliveries as 
select os.customer_id as customer_id, 
os.order_id as order_id, 
ro.runner_id as runner_id, 
rr.rating as rating, 
os.order_time as order_time, 
ro.pickup_time as pickup_time,
ro.distance as distance,
ro.duration as duration,
round(distance / (duration/60), 2) AS average_speed,
timediff(pickup_time, order_time) as time_between
from orders_staging os
join runner_orders_temp ro on os.order_id = ro.order_id
join runner_rating rr on os.order_id = rr.order_id;

select *
from sucessful_deliveries;

select count(order_id) as total_pizza
from sucessful_deliveries;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

with cte as (select runner_id, distance * 0.30 as travel_cost,
case
when pizza_id = 1 then 12
else 10
end as total
from runner_orders ro
join orders_staging os on ro.order_id = os.order_id)

select round(sum(total - travel_cost),2) as total_profit
from cte;