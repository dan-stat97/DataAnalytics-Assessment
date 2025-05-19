# DataAnalytics-Assessment

# Savings and Investment Report

This report identifies customers who have funded at least one savings plan **and** one investment plan. It lists their name, the count of each plan type, and the total amount they have deposited.

## Per-Question Explanations

### Objective
To extract user data showing:
- Users with **at least one savings plan** and **one investment plan**
- Only **funded plans** are considered (i.e., `confirmed_amount > 0`)
- Results are **sorted by total deposits** in descending order

### Approach

- **Users**: Fetched from `users_customuser`
- **Plans**: Linked via `plans_plan.owner_id`
- **Savings Accounts**: Filtered by `confirmed_amount > 0`
- **Plan Types**:
  - `plan_type_id = 1` → Savings Plan
  - `plan_type_id = 2` → Investment Plan

We use conditional `COUNT(DISTINCT CASE WHEN ...)` to track the number of each plan type per user. The total deposit amount is calculated using `SUM(sa.confirmed_amount)`.


## Challenges

### 1. **Plan Classification**
Understanding the meaning of `plan_type_id` was not directly evident in the schema. Based on conventions, we assumed:
- `1 = Savings`
- `2 = Investment`

**Resolution**: These assumptions should be validated with domain documentation or business logic owners.

### 2. **Name Construction**
The `users_customuser` table has `name`, `first_name`, and `last_name` fields. Since some rows may have only first/last names, we used:
```sql
COALESCE(u.name, CONCAT(u.first_name, ' ', u.last_name))



### Customer Transaction Frequency Classification

This report segments customers based on their **average monthly savings transactions**, grouping them into **High**, **Medium**, or **Low Frequency** tiers. It provides the count of customers in each group and the overall average number of transactions per group.


## Per-Question Explanations

### Objective
To classify customers based on how frequently they make transactions in their savings accounts and summarize the results by category.


## Approach

### Step 1: `monthly_transactions`
- Join `users_customuser` and `savings_savingsaccount` tables via `owner_id`.
- Use `DATE_FORMAT(transaction_date, '%Y-%m')` to group transactions monthly.
- Count the number of transactions each customer made per month.

### Step 2: `customer_avg`
- Calculate the **average number of transactions per month** for each customer.
- Categorize customers:
  - **High Frequency**: ≥ 10 transactions/month
  - **Medium Frequency**: 3–9 transactions/month
  - **Low Frequency**: < 3 transactions/month

### Step 3: Final Selection
- Group customers by `frequency_category`.
- For each group, calculate:
  - Total number of customers (`COUNT`)
  - Group average of average monthly transactions (`AVG` of `avg_transactions_per_month`)


## Challenges

### 1. **Categorizing Transaction Frequency**
We had to define what constitutes a high, medium, or low-frequency user. These thresholds (10, 3–9, <3) were arbitrary and may need refining based on actual business rules or customer behavior patterns.

**Resolution**: Chose practical thresholds and made them explicit via a `CASE` expression for transparency and adaptability.

### 2. **Transaction Date Grouping**
To ensure month-wise accuracy, we formatted dates using `DATE_FORMAT(..., '%Y-%m')`.

**Issue**: Some customers may have inconsistent monthly activity, which can skew averages.

**Resolution**: Aggregated on per-month basis before averaging to ensure consistent granularity.


## Next Steps

- Adjust frequency thresholds based on stakeholder feedback or empirical analysis.
- Add filters to focus on active users only (e.g., those with transactions in the past 3–6 months).
- Visualize trends over time using BI tools or charts.



# Inactive Plans Report: Investment and Regular Savings

This report identifies **inactive user plans** (investment or savings) that have **not received any transactions in the last 12 months** or have **never had a transaction** at all.


## Per-Question Explanation

### Objective
To return a list of:
- Active **investment plans** (`is_a_fund = 1`)
- Active **regular savings plans** (`is_regular_savings = 1`)
...that are inactive (no transaction or over a year since the last transaction).


## Approach

### Investment Plans Subquery
- Uses `LEFT JOIN` to capture all investment plans, even those **without any transactions**.
- Filters out archived, deleted, or inactive plans.
- Groups by plan and owner to get the **most recent transaction** (if any).
- Uses `HAVING` clause to include only:
  - Plans with `NULL` last transaction date, or
  - Plans with `last_transaction_date` older than **365 days**.

### Regular Savings Plans Subquery
- Uses `INNER JOIN` since we only care about savings accounts with transaction records.
- Similar filtering for deleted/archived/inactive plans.
- Groups by plan and owner, and filters for **inactivity > 365 days or no activity**.

### Final Step
- Combines both queries with a `UNION`.
- Orders the final results by number of inactivity days (most inactive first).


## Challenges

### 1. **Capturing Plans with No Transactions**
- `LEFT JOIN` was essential in the investment subquery to include plans **with no savings activity**.
- Without this, such plans would have been **excluded entirely**.

**Resolution**: Used `LEFT JOIN` and checked `MAX(transaction_date)` for `NULL`.


### 2. **Consistent Labeling Across Plan Types**
- Investment plans used `plan_type_id`, while regular savings required a clearer label.

**Resolution**: Used `'savings' AS type` in the second subquery to distinguish clearly.

### 3. **Avoiding Duplicates and Ensuring Accuracy**
- The combination of `GROUP BY`, `MAX(transaction_date)`, and `DATEDIFF` needed careful testing to avoid duplicate rows and miscalculated inactivity.

**Resolution**: Verified each plan appears only once with correct duration.


## Suggested Improvements

- Parameterize inactivity threshold (e.g., use `> @inactivity_threshold` instead of hardcoded 365).
- Add plan name and owner name for more readable reports.
- Export results to dashboard or scheduled alert for periodic monitoring.


# Estimated Customer Lifetime Value (CLV) Report

This report estimates the **Customer Lifetime Value (CLV)** of each user based on their transaction behavior and tenure on the platform.


## Objective

To rank customers by their **predicted long-term value**, helping the business identify and prioritize high-value customers.


## Approach

### 1. **Customer Identification**
- We fetch the `id`, full name, and calculate the **tenure in months** using the `TIMESTAMPDIFF` function.
- If `name` is null, we fall back to `first_name + last_name`.

### 2. **Transaction Aggregation**
- We count all **confirmed transactions** and **sum their amounts**.

### 3. **CLV Estimation Formula**

```sql
Estimated CLV =
    (Annualized Transaction Count) * (Average Transaction Value * 0.001)
