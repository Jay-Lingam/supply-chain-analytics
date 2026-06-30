-- ================================================
-- MODULE 1: SLA BREACH ANALYSIS
-- Supply Chain Delay & Vendor Performance Tracker
-- ================================================

USE supply_chain_db;

-- Query 1.1: Overall SLA summary
SELECT 
    sla_status,
    COUNT(*) as total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_orders,
    ROUND(AVG(delay_days), 2) as avg_delay_days,
    ROUND(AVG(review_score), 2) as avg_review_score
FROM orders_master
WHERE sla_status IS NOT NULL
GROUP BY sla_status
ORDER BY total_orders DESC;

-- Query 1.2: SLA breach by seller state (top 10 worst states)
SELECT 
    seller_state,
    COUNT(*) as total_orders,
    SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) as breached_orders,
    ROUND(SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as breach_rate_pct,
    ROUND(AVG(delay_days), 2) as avg_delay_days
FROM orders_master
WHERE seller_state IS NOT NULL
GROUP BY seller_state
HAVING total_orders > 100
ORDER BY breach_rate_pct DESC
LIMIT 10;

-- Query 1.3: SLA breach by product category (top 10 worst categories)
SELECT 
    category_english,
    COUNT(*) as total_orders,
    SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) as breached_orders,
    ROUND(SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as breach_rate_pct,
    ROUND(AVG(delay_days), 2) as avg_delay_days,
    ROUND(AVG(review_score), 2) as avg_review_score
FROM orders_master
WHERE category_english IS NOT NULL
GROUP BY category_english
HAVING total_orders > 50
ORDER BY breach_rate_pct DESC
LIMIT 10;

-- Query 1.4: Monthly breach trend
SELECT 
    purchase_year,
    purchase_month,
    COUNT(*) as total_orders,
    SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) as breached_orders,
    ROUND(SUM(CASE WHEN sla_status = 'Breached' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as breach_rate_pct,
    ROUND(AVG(delay_days), 2) as avg_delay_days
FROM orders_master
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;