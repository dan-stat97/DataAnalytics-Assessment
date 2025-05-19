-- Step 1: Calculate monthly transaction count for each customer
WITH monthly_transactions AS (
    SELECT 
        uc.id AS customer_id,
        -- Extract year-month (e.g., 2025-01) from transaction date
        DATE_FORMAT(sa.transaction_date, '%Y-%m') AS month_year,
        COUNT(*) AS transaction_count
    FROM 
        users_customuser uc
    JOIN 
        savings_savingsaccount sa ON uc.id = sa.owner_id
    GROUP BY 
        uc.id, month_year
),

-- Step 2: Calculate average monthly transactions and categorize customers
customer_avg AS (
    SELECT 
        customer_id,
        AVG(transaction_count) AS avg_transactions_per_month,
        -- Categorize customers based on average transaction frequency
        CASE 
            WHEN AVG(transaction_count) >= 10 THEN 'High Frequency'
            WHEN AVG(transaction_count) BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM 
        monthly_transactions
    GROUP BY 
        customer_id
)

-- Step 3: Group customers by frequency category and compute summary stats
SELECT 
    frequency_category,
    COUNT(customer_id) AS customer_count,                         -- Number of customers in each category
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month -- Average of the averages
FROM 
    customer_avg
GROUP BY 
    frequency_category
ORDER BY 
    -- Custom order: High > Medium > Low frequency
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        ELSE 3
    END;
