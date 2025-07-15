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
