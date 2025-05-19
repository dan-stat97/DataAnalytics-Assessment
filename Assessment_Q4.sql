SELECT     
    uc.id AS customer_id,
    
    -- Concatenate first and last names
    COALESCE(uc.name, CONCAT(uc.first_name, ' ', uc.last_name)) AS name,
    
    -- Calculate customer tenure in months since account creation
    TIMESTAMPDIFF(MONTH, uc.date_joined, CURRENT_DATE()) AS tenure_months,
    
    -- Count of all confirmed transactions
    COUNT(sa.id) AS total_transactions,
    
    -- ===== Estimated Customer Lifetime Value (CLV) Calculation =====
    ROUND(
        (
            -- Normalize transaction frequency to yearly scale
            (COUNT(sa.id) / GREATEST(TIMESTAMPDIFF(MONTH, uc.date_joined, CURRENT_DATE()), 1)) * 12
            *
            -- Average transaction value with a 0.1% margin (or weight)
            (SUM(sa.confirmed_amount) * 0.001 / GREATEST(COUNT(sa.id), 1))
        ), 
        2
    ) AS estimated_clv

FROM     
    users_customuser uc 
JOIN     
    savings_savingsaccount sa ON uc.id = sa.owner_id

WHERE     
    uc.is_account_deleted = 0   -- Skip deleted accounts
    AND uc.is_active = 1        -- Only include active users
    AND sa.confirmed_amount > 0 -- Consider only confirmed transactions

GROUP BY     
    uc.id, uc.name, uc.first_name, uc.last_name, uc.date_joined

HAVING     
    -- Ensure tenure is more than 0 months and there is at least one transaction
    TIMESTAMPDIFF(MONTH, uc.date_joined, CURRENT_DATE()) > 0
    AND COUNT(sa.id) > 0

-- Show customers with highest CLV first
ORDER BY     
    estimated_clv DESC;
