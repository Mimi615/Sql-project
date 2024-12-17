-- What are the standard ingredients for each pizza?

with cte as (select pizza_name, pr1.pizza_id, topping_id, topping_name
from pizza_recipes1 pr1
join pizza_toppings pt on pr1.toppings = pt.topping_id
join pizza_names pn on pr1.pizza_id = pn.pizza_id)

select pizza_name, group_concat(topping_name) as standard_topping
from cte
group by pizza_name;

-- What was the most commonly added extra?

SELECT 
    pt.topping_id AS Extras,
    pt.topping_name AS ExtraTopping,
    COUNT(*) AS Occurrencecount
FROM orders_staging co
INNER JOIN pizza_toppings pt
    ON FIND_IN_SET(pt.topping_id, co.extras) > 0
WHERE pt.topping_id != 0
GROUP BY pt.topping_id, pt.topping_name;

-- What was the most common exclusion?

select 
pt.topping_id as exclusions,
pt.topping_name as excluded_topping,
count(*) as Occurencecount
from orders_staging os
inner join pizza_toppings pt
	on find_in_set(pt.topping_id,os.exclusions) > 0
where pt.topping_id != 0
group by pt.topping_id, pt.topping_name;

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

select order_id, pizza_id, exclusions, extras,
case
when pizza_id = 1 and exclusions is null and extras is null then 'Meat Lovers'
when pizza_id = 2 and exclusions is null and extras is null then 'Vegetarian Lovers'
when pizza_id = 2 and (extras like 1) then 'Vegetarian Lovers - Extra Bacon'
when pizza_id = 2 and (exclusions like 4) then 'Vegetarian Lovers - Exclude Cheese'
when pizza_id = 1 and find_in_set(4,exclusions) then 'Meat Lovers - Exclude Cheese'
when pizza_id = 1 and (extras like '1') then 'Meat Lovers - Extra Bacon'
when pizza_id = 1 and (exclusions like '2,6') and (extras like '1,4') then 'Meat Lovers - Exclude BBQ sauce, Mushrooms - Extra Bacon, Cheese'
end as order_item
from orders_staging;

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

with cte as (
select order_id, pizza_id, extras,
row_number() over () as row_num
from orders_staging
)

select row_num, os.order_id, os.pizza_id, os.extras,
group_concat(distinct case
when find_in_set(pt.topping_id,os.extras) > 0 then concat('2x',topping_name)
else pt.topping_name
end
order by topping_name asc separator ',') as ingredients
from cte os
join pizza_recipes1 pr1 on os.pizza_id = pr1.pizza_id
join pizza_toppings pt on pr1.toppings = pt.topping_id
group by row_num, os.order_id, os.pizza_id, os.extras;

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

with cte1 as (select toppings, count(toppings) as total
from orders_staging os
join pizza_recipes1 pr1 on os.pizza_id = pr1.pizza_id
group by toppings),

cte2 as (select topping_id,
count(case
when find_in_set(pt.topping_id,os.exclusions) > 0 then topping_name
end) as exclusions_total
from orders_staging os
join pizza_recipes1 pr1 on os.pizza_id = pr1.pizza_id
join pizza_toppings pt on pr1.toppings = pt.topping_id
group by topping_id),

cte3 as (select topping_id,
count(case
when find_in_set(pt.topping_id,os.extras) > 0 then topping_name
end) as extras_total
from orders_staging os
join pizza_recipes1 pr1 on os.pizza_id = pr1.pizza_id
join pizza_toppings pt on pr1.toppings = pt.topping_id
group by topping_id)

select cte1.toppings, total + extras_total - exclusions_total as total
from cte1
join cte2 on cte1.toppings = cte2.topping_id
join cte3 on cte1.toppings = cte3.topping_id
order by total desc;
