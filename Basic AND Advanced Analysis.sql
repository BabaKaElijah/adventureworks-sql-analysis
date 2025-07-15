SELECT * FROM DimEmployee
SELECT * FROM DimProduct
SELECT * FROM DimGeography
SELECT * FROM DimCustomer
SELECT * FROM FactInternetSales

--List the first 10 products from the DimProduct table. Show the product name, product key, and product alternate key.

SELECT TOP 10
ProductKey,
ProductAlternateKey
EnglishProductName
FROM DimProduct

-- Question 2: Find all customers from the "United States"

SELECT *
FROM DimGeography
WHERE EnglishCountryRegionName = 'United States'

--From the DimCustomer table, count how many customers are in each gender group (e.g., M and F). Return the gender and the total count.

SELECT 
Gender,
COUNT(Gender) AS TotalCount
FROM DimCustomer
GROUP BY Gender

--From the FactInternetSales table, list the 10 most recent sales based on OrderDate. Show all columns for now.

SELECT TOP 10 *
FROM FactInternetSales
ORDER BY OrderDate DESC

--Show the total internet sales (SalesAmount) per calendar year using the FactInternetSales and DimDate tables.

SELECT 
  d.CalendarYear, 
  COUNT(*) AS NumberOfOrders,
  SUM(f.SalesAmount) AS TotalSales
FROM FactInternetSales f
JOIN DimDate d 
  ON f.OrderDateKey = d.DateKey
GROUP BY d.CalendarYear
ORDER BY d.CalendarYear;

--For each customer who made a purchase, show their full name and their total internet sales amount.

SELECT 
  c.FirstName + ' ' + c.LastName AS FullName,
  SUM(f.SalesAmount) AS TotalSales
FROM FactInternetSales f
JOIN DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY c.FirstName, c.LastName
ORDER BY TotalSales DESC;

--Use a CTE to find the average internet sales amount per product.
--Show the product name and the average sales amount, sorted by highest average first.

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

--For each product, calculate the total internet sales and assign a rank based on the total (highest sales = rank 1).
--Show the product name, total sales, and rank.

SELECT 
  p.EnglishProductName,
  SUM(f.SalesAmount) AS TotalSales,
  RANK() OVER (ORDER BY SUM(f.SalesAmount) DESC) AS SalesRank
FROM FactInternetSales f
JOIN DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY p.EnglishProductName
ORDER BY SalesRank;

-- Example: Partition by Product Subcategory

SELECT 
  sc.EnglishProductSubcategoryName AS Subcategory,
  p.EnglishProductName AS Product,
  SUM(f.SalesAmount) AS TotalSales,

  RANK() OVER (
    PARTITION BY sc.EnglishProductSubcategoryName
    ORDER BY SUM(f.SalesAmount) DESC
  ) AS RankInSubcategory,

  DENSE_RANK() OVER (
    PARTITION BY sc.EnglishProductSubcategoryName
    ORDER BY SUM(f.SalesAmount) DESC
  ) AS DenseRankInSubcategory,

  ROW_NUMBER() OVER (
    PARTITION BY sc.EnglishProductSubcategoryName
    ORDER BY SUM(f.SalesAmount) DESC
  ) AS RowNumberInSubcategory

FROM FactInternetSales f
JOIN DimProduct p ON f.ProductKey = p.ProductKey
JOIN DimProductSubcategory sc ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
GROUP BY sc.EnglishProductSubcategoryName, p.EnglishProductName
ORDER BY sc.EnglishProductSubcategoryName, RankInSubcategory;

--Show internet sales per month, and calculate:
  --Total sales for the current month
  --Previous month's sales
  --Growth (difference between months)


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



