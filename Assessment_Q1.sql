SELECT 
    u.id AS owner_id,
    --  Concatenate first and last name
    COALESCE(u.name, CONCAT(u.first_name, ' ', u.last_name)) AS name,
    
    -- Count number of funded savings plans (plan_type_id = 1)
    COUNT(DISTINCT CASE WHEN p.plan_type_id = 1 THEN p.id END) AS savings_count,
    
    -- Count number of funded investment plans (plan_type_id = 2)
    COUNT(DISTINCT CASE WHEN p.plan_type_id = 2 THEN p.id END) AS investment_count,
    
    -- Sum total confirmed deposits across all linked savings accounts
    SUM(sa.confirmed_amount) AS total_deposits
FROM users_customuser u

-- Join plans to users by owner_id
JOIN plans_plan p ON u.id = p.owner_id

-- Join savings accounts to plans; only consider confirmed transactions
JOIN savings_savingsaccount sa ON sa.plan_id = p.id AND sa.confirmed_amount > 0

-- Group results by user to aggregate savings/investment counts and deposits
GROUP BY u.id, name

-- Ensure only users who have both a savings and investment plan
HAVING savings_count > 0 AND investment_count > 0

-- Order results by total deposits in descending order
ORDER BY total_deposits DESC;

