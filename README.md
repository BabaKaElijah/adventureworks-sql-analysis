# AdventureWorks SQL Analysis

## 📌 Project Overview
This project explores real-world business questions using Microsoft’s `AdventureWorksDW2022` data warehouse. It focuses on performing advanced SQL analytics to uncover insights in areas such as profitability, sales trends, customer segmentation, and product performance. The goal is to demonstrate the use of advanced SQL techniques in solving realistic business intelligence problems — as would be required in a data analyst or BI role.

---

## 📦 Dataset Overview: AdventureWorksDW2022

`AdventureWorksDW2022` is the **latest version** of Microsoft’s sample data warehouse designed for learning and testing Business Intelligence (BI), data warehousing, and analytical reporting solutions.

### 🏭 The Story Behind the Data
Adventure Works is a **fictional bicycle manufacturing company**. The dataset represents the data warehouse side of the business — meaning it’s already cleaned, transformed, and structured using a **star schema** typical of enterprise BI systems.

The dataset includes facts and dimensions around:

- **Sales performance** (FactInternetSales, FactResellerSales)
- **Product details** (DimProduct, DimProductSubcategory, DimProductCategory)
- **Customer demographics** (DimCustomer, DimGeography)
- **Dates and time intelligence** (DimDate)
- **Employees and resellers** (DimEmployee, DimReseller)
- **Financial metrics** (sales amount, product cost, profit)

### ⭐ Schema Style
The data warehouse uses a **star schema**:
- Central **fact tables** (e.g., FactInternetSales) record measurable events.
- Surrounding **dimension tables** (e.g., DimProduct, DimCustomer, DimDate) provide descriptive context.

This setup supports fast, efficient analytical queries — exactly the kind we use in this project.

---

## 📊 Business Questions Answered

The following analysis questions were tackled using `SQL Server` and `AdventureWorksDW2022`:
1. For each customer who made a purchase, show their full name and their total internet sales amount.
```sql
SELECT 
  c.FirstName + ' ' + c.LastName AS FullName,
  SUM(f.SalesAmount) AS TotalSales
FROM FactInternetSales f
JOIN DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY c.FirstName, c.LastName
ORDER BY TotalSales DESC;
```
2. Use a CTE to find the average internet sales amount per product. Show the product name and the average sales amount, sorted by highest average first.
```sql
WITH AvgSales AS (
  SELECT 
    ProductKey,
    AVG(SalesAmount) AS AvgSale
  FROM FactInternetSales
  GROUP BY ProductKey
)

SELECT 
  p.EnglishProductName,
  a.AvgSale
FROM AvgSales a
JOIN DimProduct p ON a.ProductKey = p.ProductKey
ORDER BY a.AvgSale DESC;
```
3. Show internet sales per month, and calculate: Total sales for the current month. Previous month's sales. Growth (difference between months).
```sql
SELECT 
  d.CalendarYear,
  d.EnglishMonthName,
  d.MonthNumberOfYear,
  SUM(f.SalesAmount) AS CurrentMonthSales,

  -- Previous month's total sales
  LAG(SUM(f.SalesAmount)) OVER (
    ORDER BY d.CalendarYear, d.MonthNumberOfYear
  ) AS PreviousMonthSales,

  SUM(f.SalesAmount) - LAG(SUM(f.SalesAmount)) OVER (
    ORDER BY d.CalendarYear, d.MonthNumberOfYear
  ) AS Growth
FROM FactInternetSales f
JOIN DimDate d ON f.OrderDateKey = d.DateKey
GROUP BY d.CalendarYear, d.EnglishMonthName, d.MonthNumberOfYear
ORDER BY d.CalendarYear, d.MonthNumberOfYear;
```
4. Calculate Rolling 3-Month Average Sales per Product.
```sql
WITH MonthlySales AS (
  SELECT 
    p.ProductKey,
    p.EnglishProductName,
    d.CalendarYear,
    d.MonthNumberOfYear,
    SUM(f.SalesAmount) AS TotalSales
  FROM FactInternetSales f
  JOIN DimProduct p ON f.ProductKey = p.ProductKey
  JOIN DimDate d ON f.OrderDateKey = d.DateKey
  GROUP BY 
    p.ProductKey,
    p.EnglishProductName,
    d.CalendarYear,
    d.MonthNumberOfYear
)

SELECT
  ProductKey,
  EnglishProductName,
  CalendarYear,
  MonthNumberOfYear,
  TotalSales,

  -- Rolling 3-month average including current and previous 2 months
  AVG(TotalSales) OVER (
    PARTITION BY ProductKey
    ORDER BY CalendarYear, MonthNumberOfYear
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS Rolling3MonthAvg
FROM MonthlySales
ORDER BY ProductKey, CalendarYear, MonthNumberOfYear;
```
5. Top 3 Customers by Sales in Each Year.
```sql
WITH CustomerYearlySales AS (
SELECT 
c.FirstName + ' ' + c.LastName AS FullName,
c.CustomerKey,
d.CalendarYear,
SUM(f.SalesAmount) AS TotalSales,
ROW_NUMBER() OVER (
PARTITION BY d.CalendarYear
ORDER BY SUM(f.SalesAmount) DESC
) AS SalesRank
FROM FactInternetSales f
JOIN DimCustomer c ON f.CustomerKey = c.CustomerKey
JOIN DimDate d ON f.OrderDateKey = d.DateKey
GROUP BY d.CalendarYear, c.CustomerKey, c.FirstName, c.LastName
)
SELECT *
FROM CustomerYearlySales
WHERE SalesRank <= 3
ORDER BY CalendarYear, SalesRank;
```
6. Identify products where total monthly sales declined for 3 months in a row.
```sql
WITH MonthlyProductSales AS (
  SELECT
    p.ProductKey,
    p.EnglishProductName,
    d.CalendarYear,
    d.MonthNumberOfYear,
    CAST(CONCAT(d.CalendarYear, '-', RIGHT('0' + CAST(d.MonthNumberOfYear AS VARCHAR(2)), 2)) AS DATE) AS SaleMonth,
    SUM(f.SalesAmount) AS MonthlySales
  FROM FactInternetSales f
  JOIN DimDate d ON f.OrderDateKey = d.DateKey
  JOIN DimProduct p ON f.ProductKey = p.ProductKey
  GROUP BY p.ProductKey, p.EnglishProductName, d.CalendarYear, d.MonthNumberOfYear
),
WithLaggedSales AS (
  SELECT *,
    LAG(MonthlySales, 1) OVER (PARTITION BY ProductKey ORDER BY CalendarYear, MonthNumberOfYear) AS Prev1,
    LAG(MonthlySales, 2) OVER (PARTITION BY ProductKey ORDER BY CalendarYear, MonthNumberOfYear) AS Prev2
  FROM MonthlyProductSales
)
SELECT
  ProductKey,
  EnglishProductName,
  CalendarYear,
  MonthNumberOfYear,
  MonthlySales AS CurrentMonthSales,
  Prev1 AS LastMonthSales,
  Prev2 AS TwoMonthsAgoSales
FROM WithLaggedSales
WHERE 
  Prev2 IS NOT NULL
  AND MonthlySales < Prev1
  AND Prev1 < Prev2
ORDER BY EnglishProductName, CalendarYear, MonthNumberOfYear;
```
7. Calculate Sales Contribution % by Country.
```sql
WITH CountrySales AS (
  SELECT 
    g.EnglishCountryRegionName AS Country,
    SUM(f.SalesAmount) AS TotalSales
  FROM FactInternetSales f
  JOIN DimCustomer c ON f.CustomerKey = c.CustomerKey
  JOIN DimGeography g ON c.GeographyKey = g.GeographyKey
  GROUP BY g.EnglishCountryRegionName
),
TotalSales AS (
  SELECT SUM(TotalSales) AS GrandTotal 
  FROM CountrySales
)
SELECT 
  cs.Country,
  cs.TotalSales,
  ROUND(cs.TotalSales * 100.0 / ts.GrandTotal, 2) AS SalesPercentage
FROM CountrySales cs
CROSS JOIN TotalSales ts
ORDER BY SalesPercentage DESC;
```
8. Identify the top 10 most profitable customers based on total profit.
```sql
WITH CustomerProfit AS (
	SELECT 
	d.FirstName + ' ' + d.LastName AS FullName,
	ROUND(SUM(f.SalesAmount),0) AS TotalSalesAmount,
	ROUND(SUM(f.TotalProductCost),0) AS TotalCost,
	ROUND(SUM(f.SalesAmount - f.TotalProductCost),0) AS TotalProfit
	FROM FactInternetSales f
	JOIN DimCustomer d
	ON f.CustomerKey = d.CustomerKey
GROUP BY d.FirstName, d.LastName
),
RankedCustomers AS (
	SELECT *,
	RANK() OVER (ORDER BY TotalProfit DESC) AS ProfitRank
	FROM CustomerProfit
)
SELECT *
FROM RankedCustomers
WHERE ProfitRank <= 10
ORDER BY ProfitRank ASC
```
9. Calculate YoY sales growth for each year based on FactInternetSales.
```sql
WITH CustomerSales AS (
	SELECT 
	d.CalendarYear,
	SUM(f.SalesAmount) AS TotalSalesAmount
	FROM FactInternetSales f
	JOIN DimDate d
	ON f.OrderDateKey = d.DateKey
	GROUP BY d.CalendarYear
),
WithLaggedSales AS (
  SELECT *,
    LAG(TotalSalesAmount) OVER (ORDER BY CalendarYear) AS PrevYear
  FROM CustomerSales
)
SELECT
CalendarYear,
TotalSalesAmount,
PrevYear,
ROUND(((TotalSalesAmount - PrevYear) * 100.0) / PrevYear, 2) AS YoYGrowthPercent
FROM WithLaggedSales
ORDER BY CalendarYear;
```
10. Identify the top 5 best-selling products, based on both total sales and total profit.
```sql
WITH CustomerSales AS (
	SELECT
	p.ProductKey,
	p.EnglishProductName,
	ROUND(SUM(f.SalesAmount), 0) AS TotalSales,
	ROUND(SUM(f.TotalProductCost), 0) AS TotalCost,
	ROUND(SUM(f.SalesAmount - f.TotalProductCost), 0) AS TotalProfit
	FROM FactInternetSales f
	JOIN DimProduct p
	ON f.ProductKey = p.ProductKey
	GROUP BY p.ProductKey, P.EnglishProductName
),
RankedCustomers AS (
	SELECT *,
	RANK() OVER (ORDER BY TotalProfit DESC) AS ProfitRank
	FROM CustomerSales
)
SELECT *
FROM RankedCustomers
WHERE ProfitRank <= 5
ORDER BY ProfitRank ASC
```
11. Calculate total sales, total cost, and total profit for each Product Category
```sql
SELECT 
	pc.EnglishProductCategoryName,
	ROUND(SUM(f.SalesAmount), 0) AS TotalSales,
	ROUND(SUM(f.TotalProductCost), 0) AS TotalCost,
	ROUND(SUM(f.SalesAmount - f.TotalProductCost), 0) AS TotalProfit
FROM FactInternetSales f
JOIN DimProduct p
    ON f.ProductKey = p.ProductKey
JOIN DimProductSubcategory s
    ON p.ProductSubcategoryKey = s.ProductSubcategoryKey
JOIN DimProductCategory pc
    ON s.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY 
    pc.EnglishProductCategoryName
ORDER BY 
    TotalProfit DESC;
```
## 🧠 SQL Techniques Used

This project makes extensive use of **advanced SQL concepts**, including:

- ✅ CTEs (Common Table Expressions)  
  Used for breaking down complex logic into readable layers.

- ✅ Window Functions (`RANK()`, `LAG()`)  
  Used for ranking entities and calculating changes over time.

- ✅ Aggregate Functions (`SUM()`, `ROUND()`)  
  Used for summarizing sales, cost, and profit data.

- ✅ Multi-level Joins  
  Navigated through star schema relationships (e.g., Product → Subcategory → Category).

- ✅ Data Transformation  
  Performed dynamic calculations like profit margins and percentage contributions.

- ✅ Filtering & Ordering  
  Used `WHERE`, `GROUP BY`, `ORDER BY` for targeted, organized results.

---

## 💡 Key Learnings

- How to transform raw sales data into actionable business insights.
- Practical use of **dimensional modeling** (fact/dimension table joins).
- Interpreting trends and anomalies in financial KPIs.
- The importance of structuring queries for readability and reusability.

---

## 📂 How to Use

1. Open the project SQL scripts in **SQL Server Management Studio (SSMS)**.
2. Make sure the `AdventureWorksDW2022` database is attached.
3. Run each query in sequence or adapt them to explore further insights.
4. Feel free to modify or extend queries for deeper analysis (e.g., subcategory trends, customer churn, etc.)

---

## 🚀 Next Steps (Ideas to Extend)

- Monthly trend analysis for top products
- Regional performance heatmaps using Power BI
- Customer retention and churn analysis
- Outlier detection for abnormal sales or pricing

---

## 📎 Dataset Reference

> **AdventureWorksDW2022** is a Microsoft sample data warehouse schema used for data analysis, BI testing, and reporting scenarios.  
> Download link: https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure

---

## 👨‍💻 Author

Ellias Sithole  
📍 Johannesburg, South Africa  
🎓 Background: Mathematics & Data Analysis  
📫 [GitHub Portfolio](https://babakaelijah.github.io/portoflio-website)
