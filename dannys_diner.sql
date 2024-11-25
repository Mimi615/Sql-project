-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id as customer, sum(m.price) as total_price
from sales s
left join menu m on s.product_id = m.product_id
group by customer;

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct(order_date)) as total_days
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with first_order as (select s.customer_id as customer,
m.product_name as product_name,
s.order_date order_date,
dense_rank() over(partition by s.customer_id order by s.order_date) as row_num
from sales s
join menu m on s.product_id = m.product_id
group by customer, product_name, order_date)

select customer, product_name
from first_order
where row_num = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name as product, count(s.product_id) as total
from sales s
join menu m on s.product_id = m.product_id
group by product
order by total desc
limit 1;

-- 5. Which item was the most popular for each customer?

with popular as (select s.customer_id as customer_id, 
m.product_name as product_name,
count(s.product_id) as total,
dense_rank() over(partition by customer_id order by count(s.product_id) desc) as row_num
from sales s
join menu m on s.product_id = m.product_id
group by customer_id, product_name)

select customer_id,
product_name
from popular
where row_num = 1;

-- 6. Which item was purchased first by the customer after they became a member?

with first_order as (select s.customer_id as customer_id, me.product_name as product_name, s.order_date as order_date, m.join_date as join_date,
dense_rank() over(partition by customer_id order by order_date) as row_num
from sales s
left join members m on s.customer_id = m.customer_id
left join menu me on s.product_id = me.product_id
where s.order_date >= m.join_date)

select customer_id, product_name
from first_order
where row_num = 1;

-- 7. Which item was purchased just before the customer became a member?

with before_member as (select s.customer_id as customer_id, me.product_name as product_name, s.order_date as order_date, m.join_date as join_date,
dense_rank() over(partition by customer_id order by order_date desc) as row_num
from sales s
left join members m on s.customer_id = m.customer_id
left join menu me on s.product_id = me.product_id
where s.order_date < m.join_date)

select customer_id, product_name
from before_member
where row_num = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

with total_amount as (select s.customer_id as customer_id, 
me.product_name as product_name, 
s.order_date as order_date, 
m.join_date as join_date,
me.price as price
from sales s
left join members m on s.customer_id = m.customer_id
left join menu me on s.product_id = me.product_id
where s.order_date < m.join_date)

select customer_id, sum(price)
from total_amount
group by customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with total_points as (select s.customer_id as customer_id, 
case
	when m.product_name = 'sushi' or s.product_id = 1 then m.price * 20
    else m.price * 10
end as points
from sales s
join menu m on s.product_id = m.product_id)

select customer_id, sum(points)
from total_points
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many -- points do customer A and B have at the end of January?

with points_calc as (select s.customer_id as customer_id, me.product_name as product_name, s.order_date as order_date, m.join_date as join_date,
case
	when s.order_date between m.join_date and date_add(m.join_date, interval 7 day) then me.price * 20
    when me.product_name = 'sushi' then me.price * 20
    else me.price * 10
end j_points
from sales s
left join members m on s.customer_id = m.customer_id
left join menu me on s.product_id = me.product_id
where s.order_date >= m.join_date and s.order_date < '2021-02-01')

select customer_id, sum(j_points)
from points_calc
group by customer_id;

