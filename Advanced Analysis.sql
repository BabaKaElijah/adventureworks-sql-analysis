--Calculate Rolling 3-Month Average Sales per Product

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

--Top 3 Customers by Sales in Each Year

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

--Identify products where total monthly sales declined for 3 months in a row.

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

--Calculate Sales Contribution % by Country

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
