-- ================================================
-- MODULE 3: ROOT CAUSE ANALYSIS + MONTHLY TRENDS
-- Supply Chain Delay & Vendor Performance Tracker
-- ================================================

USE supply_chain_db;

-- Query 3.1: Pipeline stage breakdown by SLA status
SELECT
    sla_status,
    ROUND(AVG(approval_days), 2) AS avg_approval_days,
    ROUND(AVG(seller_processing_days), 2) AS avg_processing_days,
    ROUND(AVG(transit_days), 2) AS avg_transit_days,
    ROUND(AVG(days_to_deliver), 2) AS avg_total_days,
    COUNT(*) AS total_orders
FROM orders_master
WHERE sla_status IS NOT NULL
GROUP BY sla_status
ORDER BY avg_total_days DESC;

-- Query 3.2: Month over month trend using LAG()
WITH monthly_stats AS (
    SELECT
        purchase_year,
        purchase_month,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) AS breached_orders,
        ROUND(SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS breach_rate,
        ROUND(AVG(delay_days), 2) AS avg_delay_days,
        ROUND(AVG(seller_processing_days), 2) AS avg_processing_days,
        ROUND(AVG(transit_days), 2) AS avg_transit_days
    FROM orders_master
    GROUP BY purchase_year, purchase_month
    HAVING total_orders > 50
)
SELECT
    purchase_year,
    purchase_month,
    total_orders,
    breached_orders,
    breach_rate,
    avg_delay_days,
    avg_processing_days,
    avg_transit_days,
    LAG(breach_rate) OVER (ORDER BY purchase_year, purchase_month) AS prev_month_breach_rate,
    ROUND(breach_rate - LAG(breach_rate) OVER (ORDER BY purchase_year, purchase_month), 2) AS breach_rate_change,
    LAG(total_orders) OVER (ORDER BY purchase_year, purchase_month) AS prev_month_orders,
    ROUND(total_orders - LAG(total_orders) OVER (ORDER BY purchase_year, purchase_month), 0) AS order_volume_change
FROM monthly_stats
ORDER BY purchase_year, purchase_month;

-- Query 3.3: Delay by product weight bucket
SELECT
    CASE
        WHEN product_weight_g < 500 THEN '1. Light (<500g)'
        WHEN product_weight_g BETWEEN 500 AND 2000 THEN '2. Medium (500g-2kg)'
        WHEN product_weight_g BETWEEN 2000 AND 5000 THEN '3. Heavy (2kg-5kg)'
        WHEN product_weight_g BETWEEN 5000 AND 10000 THEN '4. Very Heavy (5kg-10kg)'
        ELSE '5. Extra Heavy (>10kg)'
    END AS weight_bucket,
    COUNT(*) AS total_orders,
    ROUND(AVG(delay_days), 2) AS avg_delay_days,
    ROUND(SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS breach_rate,
    ROUND(AVG(seller_processing_days), 2) AS avg_processing_days,
    ROUND(AVG(transit_days), 2) AS avg_transit_days,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM orders_master
WHERE product_weight_g IS NOT NULL
GROUP BY weight_bucket
ORDER BY weight_bucket;

-- Query 3.4: Same state vs cross state delivery performance
SELECT
    CASE
        WHEN seller_state = customer_state THEN 'Same State'
        ELSE 'Cross State'
    END AS delivery_type,
    COUNT(*) AS total_orders,
    ROUND(AVG(delay_days), 2) AS avg_delay_days,
    ROUND(AVG(transit_days), 2) AS avg_transit_days,
    ROUND(SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS breach_rate,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM orders_master
WHERE seller_state IS NOT NULL
  AND customer_state IS NOT NULL
GROUP BY delivery_type;