SELECT * FROM (
    -- ===== Subquery 1: Inactive Investment Plans (where is_a_fund = 1) =====
    SELECT 
        p.id AS plan_id,
        p.owner_id,
        p.plan_type_id AS type,  -- Use original plan type ID for investment plans
        MAX(s.transaction_date) AS last_transaction_date,
        -- Calculate days since last transaction (inactivity duration)
        DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
    FROM 
        plans_plan p
    LEFT JOIN 
        savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        p.is_deleted = 0              -- Exclude deleted plans
        AND p.is_archived = 0         -- Exclude archived plans
        AND p.status_id = 1           -- Only active plans
        AND p.is_a_fund = 1           -- Only investment plans
    GROUP BY 
        p.id, p.owner_id
    HAVING 
        -- Identify plans with no transactions or inactive for over a year
        last_transaction_date IS NULL OR DATEDIFF(CURDATE(), last_transaction_date) > 365

    UNION

    -- ===== Subquery 2: Inactive Regular Savings Plans (where is_regular_savings = 1) =====
    SELECT 
        s.plan_id,
        s.owner_id,
        'savings' AS type,            -- Mark regular savings with a readable label
        MAX(s.transaction_date) AS last_transaction_date,
        DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
    FROM 
        savings_savingsaccount s
    INNER JOIN 
        plans_plan p ON s.plan_id = p.id
    WHERE 
        p.is_deleted = 0              -- Exclude deleted plans
        AND p.is_archived = 0         -- Exclude archived plans
        AND p.status_id = 1           -- Only active plans
        AND p.is_regular_savings = 1  -- Only regular savings plans
    GROUP BY 
        s.plan_id, s.owner_id
    HAVING 
        -- Identify plans with no transactions or inactive for over a year
        last_transaction_date IS NULL OR DATEDIFF(CURDATE(), last_transaction_date) > 365
) AS combined_results

-- Order all results by inactivity duration in descending order
ORDER BY 
    inactivity_days DESC;
