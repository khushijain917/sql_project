CREATE DATABASE churn_project;
USE churn_project;


CREATE TABLE customers (
    customer_id VARCHAR(20),
    gender VARCHAR(10),
    region VARCHAR(10),
    age INT,
    plan_type VARCHAR(20)
);
CREATE TABLE subscriptions (
    customer_id VARCHAR(20),
    start_date DATE,
    end_date DATE,
    is_active TINYINT
);
CREATE TABLE usage_logs (
    customer_id VARCHAR(20),
    login_date DATE,
    total_minutes_streamed INT
);
CREATE TABLE feedback (
    customer_id VARCHAR(20),
    feedback_date DATE,
    rating INT
);

select * from feedback  ;
select * from usage_logs   ;
select * from customers  ;
select * from subscriptions ;
 
--  Identify Churned Users : 
select customer_id , end_date 
from subscriptions 
where is_active = 0;

-- Calculate Churn Rate
select 
  round( 100 * sum(case when is_active = 0 then 1 else 0 end ) /count(*) ,2 ) as churn_rate 
from subscriptions ; 

--  Churn Rate by Plan Type 
select 
c.plan_type ,
round(100* sum(case when is_active = 0 then 1 else 0 end ) / count(*) , 2 ) as churn_rate
from subscriptions s
join customers c 
on c.customer_id = s.customer_id 
group by c.plan_type ; 

-- Churn Rate by Region
select 
c.region ,
round(100* sum(case when is_active = 0 then 1 else 0 end) / count(*)  , 2) as churn_rate
from subscriptions s 
join customers c 
on c.customer_id = s.customer_id 
group by c.region 
order by churn_rate  desc ; 

-- Avg Usage Before Churn (Last 30 Days)
select 
round( avg(u.total_minutes_streamed ) , 2 ) as avg_usage_before_churn 
from subscriptions s 
join usage_logs u 
on u.customer_id = s.customer_id 
where 
s.is_active = 0 and 
u.login_date between date_sub(s.end_date, interval 30 day ) and s.end_date ;

-- active users stream_time :
SELECT 
  ROUND(AVG(u.total_minutes_streamed), 2) AS avg_usage_active_users
FROM subscriptions s
JOIN usage_logs u ON s.customer_id = u.customer_id
WHERE s.is_active = 1; 
select * from usage_logs ;

-- Average Watch Time by Plan Type (Basic/Premium)
SELECT 
  c.plan_type,
  ROUND(AVG(u.total_minutes_streamed), 2) AS avg_watch_time
FROM customers c
JOIN usage_logs u ON c.customer_id = u.customer_id
GROUP BY c.plan_type
ORDER BY avg_watch_time DESC;

-- Monthly Churn Trend (Churn Count by Month)
select 
date_format(end_date, "%y-%m") as churn_month ,
count(*) as churned_users
from subscriptions 
where is_active = 0 
group by churn_month
order by churned_users ;

-- Top 3 Genres Watched Before Churn 🍿
select 
 w.genre ,
 count(*) as total_views
from subscriptions s 
join watch_history w 
on w.customer_id = s.customer_id 
where s.is_active = 0 
and w.watch_date between date_sub(s.end_date , interval 30 day) and s.end_date
group by w.genre 
order by total_views desc 
limit 3 ;

-- coliumn not avialble 
--  High Usage But Still Churned Users
select 
 s.customer_id ,
 u.total_minutes_streamed 
 from subscriptions s
 join usage_logs u 
 on u.customer_id = s.customer_id 
 where s.is_active = 0 and 
 u.total_minutes_streamed >150
 order by total_minutes_streamed desc ;
 

-- Create one summary table with:
-- Total customers
-- Churned customers
-- Churn rate %
-- Avg usage (churned)
-- Top 1 genre before churn
-- Top churned plan 

WITH churn_summary AS (
  SELECT 
    COUNT(*) AS total_customers, 
    SUM(CASE WHEN s.is_active = 0 THEN 1 ELSE 0 END) AS churn_customers,
    ROUND(100 * SUM(CASE WHEN s.is_active = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
  FROM subscriptions s
), 

avg_usage AS (
  SELECT 
    ROUND(AVG(u.total_minutes_streamed), 2) AS avg_use
  FROM subscriptions s
  JOIN usage_logs u ON u.customer_id = s.customer_id 
  WHERE s.is_active = 0
    AND u.login_date BETWEEN DATE_SUB(s.end_date, INTERVAL 30 DAY) AND s.end_date 
), 

top_churned_plan AS (
  SELECT 
    c.plan_type
  FROM subscriptions s
  JOIN customers c ON c.customer_id = s.customer_id
  WHERE s.is_active = 0
  GROUP BY c.plan_type
  ORDER BY COUNT(*) DESC 
  LIMIT 1
)

SELECT 
  cs.total_customers,
  cs.churn_customers,
  cs.churn_rate,
  au.avg_use AS avg_usage,
  tp.plan_type AS top_churned_plan
FROM churn_summary cs 
CROSS JOIN avg_usage au 
CROSS JOIN top_churned_plan tp;








