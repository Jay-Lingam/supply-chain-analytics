-- ================================================
-- MODULE 2: VENDOR PERFORMANCE SCORECARD
-- Supply Chain Delay & Vendor Performance Tracker
-- ================================================

USE supply_chain_db;

-- Query 2.1: Full vendor scorecard with composite score and tier
WITH vendor_metrics AS (
    SELECT
        seller_id,
        seller_state,
        seller_city,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) AS breached_orders,
        SUM(CASE WHEN sla_status = 'On Time' THEN 1 ELSE 0 END) AS ontime_orders,
        ROUND(SUM(CASE WHEN sla_status = 'On Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ontime_rate,
        ROUND(AVG(delay_days), 2) AS avg_delay_days,
        ROUND(AVG(review_score), 2) AS avg_review_score,
        ROUND(AVG(seller_processing_days), 2) AS avg_processing_days,
        ROUND(SUM(price), 2) AS total_revenue,
        ROUND(AVG(price), 2) AS avg_order_value
    FROM orders_master
    WHERE seller_id IS NOT NULL
    GROUP BY seller_id, seller_state, seller_city
    HAVING total_orders >= 10
),
vendor_scored AS (
    SELECT *,
        ROUND(
            (ontime_rate * 0.5) +
            (COALESCE(avg_review_score, 3) * 10 * 0.3) +
            (LEAST(total_orders, 100) * 0.2),
        2) AS composite_score,
        RANK() OVER (ORDER BY ontime_rate DESC) AS performance_rank,
        NTILE(4) OVER (ORDER BY ontime_rate DESC) AS tier_num
    FROM vendor_metrics
)
SELECT
    seller_id,
    seller_state,
    seller_city,
    total_orders,
    breached_orders,
    ontime_rate,
    avg_delay_days,
    avg_review_score,
    avg_processing_days,
    total_revenue,
    composite_score,
    performance_rank,
    CASE tier_num
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Bronze'
        WHEN 4 THEN 'At Risk'
    END AS vendor_tier
FROM vendor_scored
ORDER BY composite_score DESC;

-- Query 2.3: Vendor tier summary
WITH vendor_metrics AS (
    SELECT
        seller_id,
        COUNT(*) AS total_orders,
        ROUND(SUM(CASE WHEN sla_status = 'On Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ontime_rate,
        ROUND(AVG(review_score), 2) AS avg_review_score
    FROM orders_master
    WHERE seller_id IS NOT NULL
    GROUP BY seller_id
    HAVING total_orders >= 10
),
vendor_tiered AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY ontime_rate DESC) AS tier_num
    FROM vendor_metrics
)
SELECT
    CASE tier_num
        WHEN 1 THEN 'Gold'
        WHEN 2 THEN 'Silver'
        WHEN 3 THEN 'Bronze'
        WHEN 4 THEN 'At Risk'
    END AS vendor_tier,
    COUNT(*) AS vendor_count,
    ROUND(AVG(ontime_rate), 2) AS avg_ontime_rate,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    ROUND(AVG(total_orders), 0) AS avg_orders_per_vendor
FROM vendor_tiered
GROUP BY tier_num
ORDER BY tier_num;

-- Query 2.4: Bottom 10 vendors (At Risk)
WITH vendor_metrics AS (
    SELECT
        seller_id,
        seller_state,
        COUNT(*) AS total_orders,
        ROUND(SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS breach_rate,
        ROUND(SUM(CASE WHEN sla_status = 'On Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ontime_rate,
        ROUND(AVG(delay_days), 2) AS avg_delay_days,
        ROUND(AVG(review_score), 2) AS avg_review_score,
        ROUND(SUM(price), 2) AS total_revenue
    FROM orders_master
    WHERE seller_id IS NOT NULL
    GROUP BY seller_id, seller_state
    HAVING total_orders >= 20
)
SELECT *
FROM vendor_metrics
ORDER BY ontime_rate ASC
LIMIT 10;