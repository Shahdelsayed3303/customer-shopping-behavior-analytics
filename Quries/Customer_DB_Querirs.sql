USE customer_behavior;
GO

-- 1) Base table view (for all raw columns)
CREATE VIEW dbo.vw_customer_behavior_base AS
SELECT *
FROM dbo.customer;
GO

-- 2) Gender revenue
CREATE VIEW dbo.vw_gender_revenue AS
SELECT
    gender,
    SUM(purchase_amount) AS Total_Revenue
FROM dbo.customer
GROUP BY gender;
GO

-- 3) Customers with discount and purchase above average
CREATE VIEW dbo.vw_discount_above_avg AS
SELECT
    customer_id,
    purchase_amount
FROM dbo.customer
WHERE discount_applied = 'Yes'
  AND purchase_amount > (
      SELECT AVG(purchase_amount)
      FROM dbo.customer
  );
GO

-- 4) Top 5 items by average rating
CREATE VIEW dbo.vw_top_items_by_rating AS
SELECT TOP 5
    item_purchased,
    ROUND(AVG(review_rating), 2) AS Average_Rating
FROM dbo.customer
GROUP BY item_purchased
ORDER BY AVG(review_rating) DESC;
GO

-- 5) Shipping type average spend
CREATE VIEW dbo.vw_shipping_avg_purchase AS
SELECT
    shipping_type,
    ROUND(AVG(purchase_amount), 2) AS Avg_purchase_amount
FROM dbo.customer
WHERE shipping_type IN ('Express', 'Standard')
GROUP BY shipping_type;
GO

-- 6) Subscription summary
CREATE VIEW dbo.vw_subscription_summary AS
SELECT
    subscription_status,
    COUNT(customer_id) AS Total_Customers,
    ROUND(AVG(purchase_amount), 2) AS Avg_Spend,
    ROUND(SUM(purchase_amount), 2) AS Total_Revenue
FROM dbo.customer
GROUP BY subscription_status;
GO

-- 7) Discount rate by item
CREATE VIEW dbo.vw_discount_rate_by_item AS
SELECT TOP 5
    item_purchased,
    CAST(
        100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) 
        AS DECIMAL(10,2)
    ) AS discount_rate
FROM dbo.customer
GROUP BY item_purchased
ORDER BY discount_rate DESC;
GO

-- 8) Customer segment count
CREATE VIEW dbo.vw_customer_segment_count AS
SELECT
    customer_segment,
    COUNT(*) AS Total_customer
FROM (
    SELECT
        customer_id,
        CASE
            WHEN previous_purchases = 1 THEN 'New'
            WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
            ELSE 'Loyal'
        END AS customer_segment
    FROM dbo.customer
) AS customer_type
GROUP BY customer_segment;
GO

-- 9) Top 3 items in each category
CREATE VIEW dbo.vw_top3_items_per_category AS
WITH item_counts AS (
    SELECT
        category,
        item_purchased,
        COUNT(customer_id) AS total_orders
    FROM dbo.customer
    GROUP BY category, item_purchased
),
ranked_items AS (
    SELECT
        category,
        item_purchased,
        total_orders,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY total_orders DESC, item_purchased
        ) AS rn
    FROM item_counts
)
SELECT
    category,
    item_purchased,
    total_orders
FROM ranked_items
WHERE rn <= 3;
GO

-- 10) Repeat buyers by subscription
CREATE VIEW dbo.vw_repeat_buyers_by_subscription AS
SELECT
    subscription_status,
    COUNT(CASE WHEN previous_purchases > 5 THEN 1 END) AS Repeat_Buyers
FROM dbo.customer
GROUP BY subscription_status;
GO

-- 11) Age group revenue
CREATE VIEW dbo.vw_age_group_revenue AS
SELECT
    age_group,
    SUM(purchase_amount) AS Total_revenue
FROM dbo.customer
GROUP BY age_group;
GO