-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT WEEK(registration_date,1) AS week_of_year,
   COUNT(runner_id) as total_runners_reg
FROM runners
GROUP BY week_of_year
ORDER BY week_of_year;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select avg(extract(minute from pickup_time) - extract(minute from order_time))
from delivered_orders;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?

with order_group as (select order_id, count(pizza_id) as pizza_total, timediff(pickup_time,order_time) as time_diff
from delivered_orders
group by order_id, pickup_time, order_time)

select pizza_total, FROM_UNIXTIME(AVG(UNIX_TIMESTAMP(time_diff))) as average
from order_group
group by pizza_total;

-- What was the average distance travelled for each customer?

select customer_id, round(avg(distance), 2) as avg_distance
from delivered_orders
group by customer_id
order by avg_distance desc;

-- What was the difference between the longest and shortest delivery times for all orders?

select max(duration) - min(duration) as difference_delivery
from runner_orders_temp; 

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT DISTINCT order_id, runner_id, 
  round(distance / (duration/60), 2) AS average_speed
FROM delivered_orders
ORDER BY runner_id, average_speed;

-- What is the successful delivery percentage for each runner?

with percentage as(select runner_id, 
sum(case
when cancellation is null then 1
else 0
end) as delivered,
count(runner_id) as total
from runner_orders_temp
group by runner_id)

select runner_id, round((delivered/total) * 100,2) as successful_deliver_percentage
from percentage
group by runner_id;


