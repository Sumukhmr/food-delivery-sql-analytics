-- ============================================================
-- ZOMATO FOOD DELIVERY ANALYTICS PROJECT
-- PostgreSQL Queries | 25 Business Analytics Questions
-- ============================================================

-- Q1. List all restaurants in Bengaluru that have online delivery,
--     ordered by rating from highest to lowest.

SELECT * FROM "restaurants"
WHERE "city" = 'Bengaluru'
AND "has_online_delivery" = 'Yes'
ORDER BY "rating" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q2. Find the top 10 most expensive menu items across all restaurants.
--     Show the item name, restaurant ID, cuisine, and price.

SELECT "item_name","restaurant_id","cuisine","price"
FROM "menu_items"
ORDER BY "price" DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────

-- Q3. How many customers registered each year? Order the result by year.

SELECT
	EXTRACT(YEAR FROM "registration_date") AS "year",
	COUNT(*) AS "customer_count"
FROM "customers"
GROUP BY "year"
ORDER BY "year";

-- ─────────────────────────────────────────────────────────────

-- Q4. What is the count of orders placed through each payment method?
--     Order by count from highest to lowest.

SELECT
	"payment_method",
	COUNT(*) AS "Total_count"
FROM "orders"
GROUP BY "payment_method"
ORDER BY "Total_count" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q5. Find all orders where a discount was applied and the total amount
--     was above 500.

SELECT "order_id","customer_id","total_amount","discount_applied"
FROM "orders"
WHERE "discount_applied" != 0
AND "total_amount" > 500;

-- Q6. Find the top 5 cities by total order revenue.

SELECT
	ct."city",
	SUM(od."total_amount") AS "Total_revenue"
FROM "customers" ct
INNER JOIN "orders" od ON ct."customer_id" = od."customer_id"
GROUP BY ct."city"
ORDER BY "Total_revenue" DESC
LIMIT 5;

-- ─────────────────────────────────────────────────────────────

-- Q7. Which restaurants have received the highest average overall rating
--     from reviews? Show top 10. Only consider restaurants with at
--     least 10 reviews.

SELECT
	rt."restaurant_id",
	rt."restaurant_name",
	COUNT(*) AS "Total_reviews",
	ROUND(AVG(re."overall_rating"),2) AS "Average_overall_rating"
FROM "restaurants" rt
INNER JOIN "reviews" re ON rt."restaurant_id" = re."restaurant_id"
GROUP BY rt."restaurant_id",rt."restaurant_name"
HAVING COUNT(*) >= 10
ORDER BY "Average_overall_rating" DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────

-- Q8. Find customers who have placed more than 10 orders.
--     Show their name, city, and order count.

SELECT
	ct."customer_id",
	ct."customer_name",
	ct."city",
	COUNT(*) AS "Total_orders"
FROM "customers" ct
INNER JOIN "orders" od ON od."customer_id" = ct."customer_id"
GROUP BY ct."customer_id",ct."customer_name",ct."city"
HAVING COUNT(*) > 10
ORDER BY "Total_orders" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q9. What is the monthly revenue trend for the year 2023?
--     Show month name, total revenue, and total orders. Order by month.

SELECT
	TO_CHAR("order_date",'Month') AS "Month_Name",
	EXTRACT(MONTH FROM "order_date") AS "Month_no",
	SUM("total_amount") AS "Total_revenue",
	COUNT(*) AS "Total_no_orders"
FROM "orders"
WHERE EXTRACT(YEAR FROM "order_date") = 2023
GROUP BY "Month_Name","Month_no"
ORDER BY "Month_no";

-- ─────────────────────────────────────────────────────────────

-- Q10. Find the most popular food item by total quantity ordered
--      in each city.

WITH "cte" AS (
	SELECT
		"mi"."item_name",
		"rt"."city",
		SUM("oi"."quantity") AS "total_quantity",
		RANK() OVER (
			PARTITION BY "rt"."city"
			ORDER BY SUM("oi"."quantity") DESC
		) AS "rnk"
	FROM "order_items" "oi"
	JOIN "menu_items" "mi" ON "mi"."menu_item_id" = "oi"."menu_item_id"
	JOIN "orders" "od" ON "od"."order_id" = "oi"."order_id"
	JOIN "restaurants" "rt" ON "rt"."restaurant_id" = "od"."restaurant_id"
	GROUP BY "mi"."item_name","rt"."city"
)
SELECT "city","item_name","total_quantity"
FROM "cte"
WHERE "rnk" = 1
ORDER BY "city";

-- ─────────────────────────────────────────────────────────────

-- Q11. What percentage of orders were cancelled in each city?

SELECT
	ct."city",
	COUNT(od."order_id") AS "Total_orders",
	COUNT(od."order_id") FILTER (WHERE od."status" = 'Cancelled') AS "Total_cancelled_orders",
	ROUND(COUNT(od."order_id") FILTER (WHERE od."status" = 'Cancelled') * 100.0
	/ COUNT(od."order_id"),2) AS "Cancellation_pct"
FROM "customers" ct
INNER JOIN "orders" od USING("customer_id")
GROUP BY ct."city"
ORDER BY "Cancellation_pct" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q12. For each restaurant, find the average delivery time for
--      delivered orders only. Show restaurants where avg > 60 mins.

SELECT
	rt."restaurant_id",
	rt."restaurant_name",
	ROUND(AVG(od."delivery_time_mins"),2) AS "Avg_delivery_time"
FROM "restaurants" rt
INNER JOIN "orders" od USING("restaurant_id")
WHERE od."status" = 'Delivered'
GROUP BY rt."restaurant_id",rt."restaurant_name"
HAVING ROUND(AVG(od."delivery_time_mins"),2) > 60
ORDER BY "Avg_delivery_time" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q13. Find customers who have ordered from 5 or more distinct restaurants.

SELECT
	ct."customer_id",
	ct."customer_name",
	COUNT(DISTINCT od."restaurant_id") AS "Distinct_restaurants"
FROM "customers" ct
INNER JOIN "orders" od USING("customer_id")
GROUP BY ct."customer_id",ct."customer_name"
HAVING COUNT(DISTINCT od."restaurant_id") >= 5
ORDER BY "Distinct_restaurants" DESC;

-- Q14. Rank restaurants within each city by total revenue.
--      Use DENSE_RANK. Show only top 3 per city.

WITH "cte" AS (
	SELECT
		rt."restaurant_id",
		rt."restaurant_name",
		rt."city",
		SUM(od."total_amount") AS "total_revenue",
		DENSE_RANK() OVER(
			PARTITION BY rt."city"
			ORDER BY SUM(od."total_amount") DESC
		) AS "rnk"
	FROM "restaurants" rt
	JOIN "orders" od USING("restaurant_id")
	GROUP BY rt."restaurant_id",rt."restaurant_name",rt."city"
)
SELECT
	"city",
	"restaurant_id",
	"restaurant_name",
	"total_revenue",
	"rnk"
FROM "cte"
WHERE "rnk" <= 3
ORDER BY "city","rnk";

-- ─────────────────────────────────────────────────────────────

-- Q15. Calculate month-over-month revenue growth percentage
--      for 2022 and 2023.

WITH "cte" AS (
	SELECT
		EXTRACT(YEAR FROM "order_date") AS "Year",
		EXTRACT(MONTH FROM "order_date") AS "Month",
		SUM("total_amount") AS "Total"
	FROM "orders"
	GROUP BY "Year","Month"
),
"cte2" AS (
	SELECT
		"Year",
		"Month",
		"Total",
		LAG("Total") OVER(ORDER BY "Year","Month") AS "Prev",
		"Total" - LAG("Total") OVER(ORDER BY "Year","Month") AS "Difference"
	FROM "cte"
)
SELECT
	*,
	ROUND("Difference" * 100.0 / "Prev",2) AS "Growth_Percentage"
FROM "cte2"
ORDER BY "Year","Month";

-- ─────────────────────────────────────────────────────────────

-- Q16. For each customer, calculate a running total of spend
--      and a running count of orders over time.

SELECT
	ct."customer_id",
	ct."customer_name",
	od."order_date",
	od."total_amount",
	SUM(od."total_amount") OVER(
		PARTITION BY od."customer_id"
		ORDER BY od."order_date"
	) AS "Running_total",
	COUNT(od."order_id") OVER(
		PARTITION BY od."customer_id"
		ORDER BY od."order_date"
	) AS "Running_count"
FROM "customers" ct
INNER JOIN "orders" od USING("customer_id")
ORDER BY ct."customer_id" ASC,od."order_date" ASC;

-- ─────────────────────────────────────────────────────────────

-- Q17. Find the top 3 best-selling menu items per restaurant
--      based on total quantity sold.

WITH "cte" AS (
	SELECT
		me."menu_item_id",
		me."item_name",
		me."restaurant_id",
		SUM(od."quantity") AS "Total_quantity"
	FROM "order_items" od
	INNER JOIN "menu_items" me USING("menu_item_id")
	GROUP BY me."menu_item_id",me."item_name",me."restaurant_id"
),
"cte2" AS (
	SELECT
		ct."menu_item_id",
		ct."item_name",
		ct."restaurant_id",
		ct."Total_quantity",
		DENSE_RANK() OVER(
			PARTITION BY ct."restaurant_id"
			ORDER BY ct."Total_quantity" DESC
		) AS "Rank"
	FROM "cte" ct
)
SELECT
	ct."menu_item_id",
	ct."item_name",
	me."restaurant_id",
	me."restaurant_name",
	ct."Total_quantity",
	ct."Rank"
FROM "cte2" ct
INNER JOIN "restaurants" me USING("restaurant_id")
WHERE ct."Rank" <= 3
ORDER BY me."restaurant_id",ct."Rank";

-- ─────────────────────────────────────────────────────────────

-- Q18. For each customer, find the number of days between their
--      first and most recent order. Show only spans > 365 days.

WITH "cte" AS (
	SELECT
		"customer_id",
		MIN("order_date") AS "First_Order",
		MAX("order_date") AS "Latest_Order",
		MAX("order_date") - MIN("order_date") AS "Difference_in_days"
	FROM "orders"
	GROUP BY "customer_id"
)
SELECT
	cto."customer_name",
	ct."First_Order",
	ct."Latest_Order",
	ct."Difference_in_days"
FROM "customers" cto
INNER JOIN "cte" ct ON ct."customer_id" = cto."customer_id"
WHERE ct."Difference_in_days" > 365
ORDER BY ct."Difference_in_days" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q19. Find restaurants whose average order value is above the
--      platform average. Show the difference.

WITH "platform_avg" AS (
	SELECT ROUND(AVG("total_amount"),2) AS "total_avg"
	FROM "orders"
),
"restaurant_avg" AS (
	SELECT
		"restaurant_id",
		ROUND(AVG("total_amount"),2) AS "rest_avg"
	FROM "orders"
	GROUP BY "restaurant_id"
)
SELECT
	rt."restaurant_name",
	ra."rest_avg" AS "restaurant_avg_value",
	pa."total_avg" AS "platform_avg_value",
	ROUND(ra."rest_avg" - pa."total_avg",2) AS "difference"
FROM "restaurant_avg" ra
JOIN "restaurants" rt USING("restaurant_id")
CROSS JOIN "platform_avg" pa
WHERE ra."rest_avg" > pa."total_avg"
ORDER BY "difference" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q20. Identify repeat customers -- those who ordered from the
--      same restaurant more than once.

WITH "cte" AS (
	SELECT
		"restaurant_id",
		"customer_id",
		COUNT("customer_id") AS "Total_count"
	FROM "orders"
	GROUP BY "restaurant_id","customer_id"
	HAVING COUNT("customer_id") > 1
)
SELECT
	rt."restaurant_name",
	co."customer_name",
	ct."Total_count"
FROM "cte" ct
INNER JOIN "restaurants" rt ON rt."restaurant_id" = ct."restaurant_id"
INNER JOIN "customers" co ON ct."customer_id" = co."customer_id"
ORDER BY ct."Total_count" DESC;

-- Q21. Cohort analysis -- customers grouped by first order month.
--      Track how many returned in Month 1, 2, and 3.

WITH "cte1" AS (
	SELECT
		"customer_id",
		DATE_TRUNC('month', MIN("order_date")) AS "cohort_month"
	FROM "orders"
	GROUP BY "customer_id"
),
"cte2" AS (
	SELECT
		od."customer_id",
		DATE_TRUNC('month', od."order_date") AS "order_month",
		ct."cohort_month"
	FROM "orders" od
	JOIN "cte1" ct ON ct."customer_id" = od."customer_id"
),
"cte3" AS (
	SELECT
		"customer_id",
		"cohort_month",
		EXTRACT(YEAR FROM AGE("order_month","cohort_month")) * 12 +
		EXTRACT(MONTH FROM AGE("order_month","cohort_month")) AS "month_number"
	FROM "cte2"
)
SELECT
	TO_CHAR("cohort_month",'YYYY-MM') AS "cohort_month",
	COUNT(DISTINCT CASE WHEN "month_number" = 0 THEN "customer_id" END) AS "month_0",
	COUNT(DISTINCT CASE WHEN "month_number" = 1 THEN "customer_id" END) AS "month_1",
	COUNT(DISTINCT CASE WHEN "month_number" = 2 THEN "customer_id" END) AS "month_2",
	COUNT(DISTINCT CASE WHEN "month_number" = 3 THEN "customer_id" END) AS "month_3"
FROM "cte3"
GROUP BY "cohort_month"
ORDER BY "cohort_month";

-- ─────────────────────────────────────────────────────────────

-- Q22. Segment customers into Gold, Silver, Bronze based on
--      total spend. Show count and revenue per segment.

WITH "cte" AS (
	SELECT
		ct."customer_id",
		ct."customer_name",
		SUM("total_amount") AS "total_spent"
	FROM "orders" od
	JOIN "customers" ct ON ct."customer_id" = od."customer_id"
	GROUP BY ct."customer_id",ct."customer_name"
),
"cte2" AS (
	SELECT
		"customer_id",
		"customer_name",
		"total_spent",
		CASE
			WHEN "total_spent" > 5000 THEN 'Gold'
			WHEN "total_spent" BETWEEN 2000 AND 5000 THEN 'Silver'
			ELSE 'Bronze'
		END AS "segment"
	FROM "cte"
)
SELECT
	"segment",
	COUNT("customer_id") AS "customer_count",
	SUM("total_spent") AS "total_revenue"
FROM "cte2"
GROUP BY "segment"
ORDER BY "total_revenue" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q23. Find the peak ordering hour of the day for each city.

WITH "cte" AS (
	SELECT
		ct."city",
		EXTRACT(HOUR FROM od."order_time") AS "hour",
		COUNT(od."order_id") AS "order_count",
		RANK() OVER(
			PARTITION BY ct."city"
			ORDER BY COUNT(od."order_id") DESC
		) AS "rnk"
	FROM "orders" od
	JOIN "customers" ct ON ct."customer_id" = od."customer_id"
	GROUP BY ct."city",EXTRACT(HOUR FROM od."order_time")
)
SELECT
	"city",
	"hour" AS "peak_hour",
	"order_count"
FROM "cte"
WHERE "rnk" = 1
ORDER BY "city";

-- ─────────────────────────────────────────────────────────────

-- Q24. For each cuisine type, calculate total orders,
--      avg food rating, and avg menu item price.

WITH "cte" AS (
	SELECT
		mi."cuisine",
		COUNT(od."order_id") AS "Total_orders"
	FROM "order_items" oi
	INNER JOIN "menu_items" mi ON mi."menu_item_id" = oi."menu_item_id"
	INNER JOIN "orders" od ON od."order_id" = oi."order_id"
	GROUP BY mi."cuisine"
),
"cte2" AS (
	SELECT
		mi."cuisine",
		ROUND(AVG(re."food_rating"),2) AS "Avg_food_rating"
	FROM "reviews" re
	INNER JOIN "orders" od ON od."order_id" = re."order_id"
	INNER JOIN "order_items" oi ON oi."order_id" = od."order_id"
	INNER JOIN "menu_items" mi ON mi."menu_item_id" = oi."menu_item_id"
	GROUP BY mi."cuisine"
),
"cte3" AS (
	SELECT
		mi."cuisine",
		ROUND(AVG(mi."price"),2) AS "Avg_price"
	FROM "menu_items" mi
	GROUP BY mi."cuisine"
)
SELECT
	ct."cuisine",
	ct."Total_orders",
	ct2."Avg_food_rating",
	ct3."Avg_price"
FROM "cte" ct
INNER JOIN "cte2" ct2 ON ct2."cuisine" = ct."cuisine"
INNER JOIN "cte3" ct3 ON ct3."cuisine" = ct."cuisine"
ORDER BY ct."Total_orders" DESC;

-- ─────────────────────────────────────────────────────────────

-- Q25. Restaurant performance scorecard with composite score.
--      Show top 20 restaurants.

WITH "cte" AS (
	SELECT
		od."restaurant_id",
		COUNT(od."order_id") AS "Total_orders",
		SUM(od."total_amount") AS "Total_revenue",
		ROUND(AVG(CASE WHEN od."status" = 'Delivered'
			THEN od."delivery_time_mins" END),2) AS "Avg_delivery_time",
		ROUND(COUNT(CASE WHEN od."status" = 'Cancelled'
			THEN 1 END) * 1.0 / COUNT(od."order_id"),4) AS "Cancellation_rate"
	FROM "orders" od
	GROUP BY od."restaurant_id"
),
"cte2" AS (
	SELECT
		"restaurant_id",
		ROUND(AVG("overall_rating"),2) AS "Avg_overall_rating"
	FROM "reviews"
	GROUP BY "restaurant_id"
),
"cte3" AS (
	SELECT
		rt."restaurant_id",
		rt."restaurant_name",
		rt."city",
		ct."Total_orders",
		ct."Total_revenue",
		ct."Avg_delivery_time",
		ct2."Avg_overall_rating",
		ct."Cancellation_rate",
		ROUND(
			(ct2."Avg_overall_rating" * 0.4)
			+ (1.0 / NULLIF(ct."Avg_delivery_time",0) * 10 * 0.3)
			+ ((1 - ct."Cancellation_rate") * 0.3)
		,4) AS "Composite_score"
	FROM "restaurants" rt
	INNER JOIN "cte" ct ON ct."restaurant_id" = rt."restaurant_id"
	INNER JOIN "cte2" ct2 ON ct2."restaurant_id" = rt."restaurant_id"
)
SELECT
	"restaurant_id",
	"restaurant_name",
	"city",
	"Total_orders",
	"Total_revenue",
	"Avg_delivery_time",
	"Avg_overall_rating",
	"Cancellation_rate",
	"Composite_score"
FROM "cte3"
ORDER BY "Composite_score" DESC
LIMIT 20;
