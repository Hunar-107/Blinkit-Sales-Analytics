# Blinkit — Retail Sales & Customer Analytics

## Project Overview
This project explores a synthetic retail dataset modeled on Blinkit, an Indian quick-commerce platform, covering transactions from March 2023 to November 2024. The objective is to evaluate business performance, understand product demand and identify opportunities to improve customer retention.

The analysis uses PostgreSQL across four relational tables, with Microsoft Excel for executive dashboard reporting.

## Executive Summary
- **Customer retention presents a potential growth opportunity.** Monthly repeat-purchase rates generally range between 8% and 10%, suggesting an opportunity to investigate customer reactivation.
- **Sales volume alone is insufficient for evaluating products.** Correlation between revenue and quantity ranks decreases from 0.965 at the product-type level to 0.770 at the SKU level.
- **Revenue is relatively diversified.** No category contributes more than 12% of revenue; the five leading categories account for approximately 51.3%.

Data validation also identified significant discrepancies between order-level and item-level revenue.

## Business Performance Dashboard

| Key Performance Indicator | Value |
|---|---:|
| Total Revenue | ₹1.10 Cr |
| Total Orders | 5,000 |
| Total Units Sold | 10,034 |
| Average Order Value | ₹2,201.86 |
| Product Categories | 11 |

## 1. Business Performance

| Leading Category | Revenue | Revenue Share |
|---|---:|---:|
| Dairy & Breakfast | ₹12.44 L | 11.30% |
| Household Care | ₹11.36 L | 10.32% |
| Pet Care | ₹11.25 L | 10.22% |
| Fruits & Vegetables | ₹10.85 L | 9.86% |
| Pharmacy | ₹10.56 L | 9.59% |

Revenue is relatively evenly distributed across categories. Monthly fluctuations make individual month comparisons insufficient to establish sustained growth or decline.

**Recommendation:** Monitor category performance over longer periods before making significant inventory or resource allocation decisions.

## 2. Product Performance

| Leading Product Type | Revenue |
|---|---:|
| Pet Treats | ₹5.26 L |
| Toilet Cleaner | ₹4.35 L |
| Lotion | ₹4.34 L |
| Dish Soap | ₹4.21 L |
| Cough Syrup | ₹4.08 L |

Products were independently ranked by revenue and quantity sold.

| Level of Analysis | Correlation of Ranks |
|---|---:|
| Product Type | 0.965 |
| Individual SKU | 0.770 |

The analysis correlates within-group ranks, rather than raw revenue and quantity values. The weaker association at SKU level suggests greater variation in relative revenue and volume performance.

**Recommendation:** Evaluate individual SKUs using revenue, quantity and profitability metrics together. Investigate ranking differences to identify potential pricing and assortment opportunities.

## 3. Customer Retention
Customers were grouped into monthly cohorts based on their first observed purchase. Retention denominators include only cohorts old enough to reach the corresponding cohort age.

- First-month retention: 9.09%.
- Second-month retention: 9.49%.
- Monthly retention generally remained between 8% and 10% throughout much of the observation period.
- Revenue per active customer generally ranged between ₹2,100 and ₹2,500.

These rates measure purchasing activity in individual months, not permanent customer churn.

**Recommendation:** Investigate purchasing frequency across customer segments and test targeted reactivation campaigns, measuring repeat purchases and incremental revenue.

## 4. Data Validation and Limitations
- Order-level revenue totaled ₹1.10 crore, while item quantities multiplied by unit prices totaled ₹49.72 lakh. Revenue reporting therefore uses order totals consistently.
- Each observed order has one order-item record, allowing order revenue to be attributed to products without duplicating order totals in this dataset.
- Precomputed customer purchasing metrics did not consistently match observed transactions; customer purchasing metrics were calculated from orders.
- Partial calendar months were excluded from the monthly revenue chart but retained in overall totals. The incomplete final month may understate retention, especially at later cohort ages.
- The original SQL scripts preserve the exploratory workflow. Monthly LAG ordering is not explicitly guaranteed, and positive revenue-rank-minus-quantity-rank differences indicate stronger relative quantity rankings, not stronger relative revenue rankings. No individual SKU conclusions are drawn from those labels. Some dashboard outputs were extracted from intermediate query results.

The dataset is synthetic; findings demonstrate analytical methodology rather than verified conclusions about Blinkit's actual operations.

## 5. Technical Implementation
**Tools:** PostgreSQL, Microsoft Excel, Visual Studio Code.

SQL techniques include multi-table joins, aggregations, CTEs, window functions, partitioned rankings, month-over-month analysis, rank correlation, customer segmentation and eligibility-adjusted cohort retention.

## Data Source
[Blinkit Sales Dataset — Kaggle](https://www.kaggle.com/datasets/akxiit/blinkit-sales-dataset)
