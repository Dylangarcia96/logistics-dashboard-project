# Logistics Analytics Project – Technical Deep Dive

## 1. Overview

This document provides a technical walkthrough of the end-to-end analytics pipeline implemented in this project, consisting in three main steps:

- Synthetic data generation in Python;
- Relational modelling and transformations in SQL Server;
- Analytical modelling, DAX measures, and visualisation logic in Power BI.

The goal was to simulate a realistic logistics environment and demonstrate best practices in data engineering, analytics modelling, and insight generation.

## 2. Data Generation on Python
### 2.1 Objective

With a view to making a unique, creative project, all datasets were synthetically generated while preserving realistic logistics behaviour, particularly when it comes to:

- Supplier lead times and reliability;
- Purchase volume variability;
- Inventory inflows and outflows;
- Delivery delays.

### 2.2 Tools and Libraries

- pandas – data structures and export
- numpy – random distributions
- faker – realistic entity names
- random – controlled randomness

A fixed random seed (42) was used to ensure reproducibility.



```python
# Import libraries
import pandas as pd
import numpy as np
from faker import Faker
import random

fake = Faker()

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

# Generate synthetic data tables

# 1. SUPPLIERS

num_suppliers = 20
suppliers = []

for i in range(1, num_suppliers + 1):
    suppliers.append({
        "supplier_id": i,
        "supplier_name": fake.company(),
        "country": fake.country(),
        "lead_time_days": np.random.randint(5, 30),
        "on_time_rate": round(np.random.uniform(0.7, 0.99), 2),
        "freight_cost": np.random.randint(200, 3000)
    })

df_suppliers = pd.DataFrame(suppliers)
df_suppliers.to_csv("suppliers.csv", index=False)


# 2. PRODUCTS

num_products = 80
products = []

for i in range(1, num_products + 1):
    products.append({
        "product_id": i,
        "product_name": fake.word().capitalize() + " " + fake.word().capitalize(),
        "category": random.choice(["Electronics", "Furniture", "Office Supplies", "Food", "Hardware"]),
        "unit_cost": round(np.random.uniform(2, 250), 2),
        "supplier_id": np.random.randint(1, num_suppliers + 1)
    })

df_products = pd.DataFrame(products)
df_products.to_csv("products.csv", index=False)


# 3. PURCHASE ORDERS

num_orders = 500
purchase_orders = []

for i in range(1, num_orders + 1):
    order_date = fake.date_between(start_date="-1y", end_date="today")
    qty = np.random.randint(10, 300)
    
    purchase_orders.append({
        "order_id": i,
        "product_id": np.random.randint(1, num_products + 1),
        "order_date": order_date,
        "quantity_ordered": qty,
        "total_cost": round(qty * np.random.uniform(5, 150), 2)
    })

df_po = pd.DataFrame(purchase_orders)
df_po.to_csv("purchase_orders.csv", index=False)


# 4. INVENTORY MOVEMENTS

num_products = 80
num_movements_per_product = 18
opening_stock = 500

inventory_movements = []
movement_id = 1

for product_id in range(1, num_products + 1):

    # OPENING BALANCE
    start_date = fake.date_between(start_date="-1y", end_date="-11m")

    inventory_movements.append({
        "movement_id": movement_id,
        "product_id": product_id,
        "movement_type": "OPENING",
        "quantity": opening_stock,
        "movement_date": start_date
    })
    movement_id += 1

    current_stock = opening_stock

    # FUTURE MOVEMENTS
    movement_dates = sorted(
        fake.date_between(start_date=start_date, end_date="today")
        for _ in range(num_movements_per_product)
    )

    for movement_date in movement_dates:

        movement_type = random.choice(["IN", "OUT"])

        if movement_type == "IN":
            qty = np.random.randint(20, 150)
            current_stock += qty

        else:  # OUT
            max_out = min(120, current_stock)
            if max_out <= 0:
                continue

            qty = np.random.randint(1, max_out + 1)
            current_stock -= qty

        inventory_movements.append({
            "movement_id": movement_id,
            "product_id": product_id,
            "movement_type": movement_type,
            "quantity": qty,
            "movement_date": movement_date
        })
        movement_id += 1

dfinv = pd.DataFrame(inventory_movements)
dfinv.to_csv("inventory_movements.csv", index=False)


# 5. DELIVERY TIMES

delivery_times = []

df_po_merged = df_po.merge(df_products[["product_id", "supplier_id"]], on="product_id", how="left")

for idx, row in df_po_merged.iterrows():
    supplier_id = row["supplier_id"]
    
    expected_lt = int(df_suppliers.loc[df_suppliers["supplier_id"] == supplier_id, "lead_time_days"].values[0])
    
    actual_lt = max(1, int(np.random.normal(expected_lt, 3)))
    
    delivery_date = pd.to_datetime(row["order_date"]) + pd.Timedelta(days=actual_lt)
    
    delivery_times.append({
        "order_id": row["order_id"],
        "product_id": row["product_id"],
        "supplier_id": supplier_id,
        "order_date": row["order_date"],
        "expected_lead_time_days": expected_lt,
        "actual_lead_time_days": actual_lt,
        "delay_days": actual_lt - expected_lt,
        "expected_delivery_date": pd.to_datetime(row["order_date"]) + pd.Timedelta(days=expected_lt),
        "actual_delivery_date": delivery_date
    })

df_deliveries = pd.DataFrame(delivery_times)
df_deliveries.to_csv("delivery_times.csv", index=False)

print("Synthetic supply-chain dataset created successfully!")

```

### 2.3 Core Tables Generated
#### Suppliers (20 rows - 20 suppliers)

Each supplier includes:

- Supplier ID
- Supplier name
- Lead time (days)
- On-time delivery rate
- Freight cost
- Country of origin

These attributes later enable correlation analysis between reliability, cost, and lead time.

#### Products (80 rows - 80 products)

Products were assigned:

- A name
- An ID
- A supplier ID
- A product category
- A unit cost

This structure supports supplier–product–category rollups in Power BI.

#### Purchase Orders (500 rows - 500 purchase orders)

Purchase orders were generated with random order dates over a 1-year window, with variable quantities and a calculated total cost. It includes:

- Order ID
- Product ID
- Order Date
- Quantity Ordered
- Total Cost

#### Inventory Movements (1517 rows - 1517 inventory movements)

An opening balance per product was initialised and OUT movements were constrained to available stock. This prevents unrealistic negative inventory at the product level.

This table includes the following columns:

- Movement ID
- Product ID
- Movement Type (OPENING - IN - OUT)
- Quantity
- Movement Date

#### Delivery Times (500 rows - 500 purchase orders)

Delivery performance was simulated independently from purchase orders using expected lead time from supplier master data, actual lead time generated via a normal distribution, and calculated delay days. This separation reflects real systems where delivery tracking is operationally distinct from procurement.

This table includes the following columns:

- Order ID
- Product ID
- Supplier ID
- Order Date
- Expected Lead Time Days
- Actual Lead Time Days
- Delay Days
- Expected Delivery Date
- Actual Delivery Date

### 2.4 EDA in Python

The datasets were explored to understand data types, distribution, and potential quality issues.

```python

# Data exploration - Delivery Times
dfdel = pd.read_csv('delivery_times.csv')
dfdel.describe()
dfdel.info()

# Data exploration - Inventory Movements
dfinv = pd.read_csv('inventory_movements.csv')
dfinv.describe()
dfinv.info()

# Data exploration - Purchase Orders
dfpo = pd.read_csv('purchase_orders.csv')
dfpo.describe()
dfpo.info()
dfpo.head()

# Data exploration - Products
dfprod = pd.read_csv('products.csv')
dfprod.describe()
dfprod.info()

# Data exploration - Suppliers
dfsupp = pd.read_csv('suppliers.csv')
dfsupp.describe()
dfsupp.info()

# Check that categories in products table don't have misspelings
dfprod.groupby('category').size()

# Create a category dimension table.
dfcategory = dfprod[['category']].drop_duplicates().reset_index(drop=True)
dfcategory['category_id'] = dfcategory.index + 1
dfcategory.head(5)

# Save category table as csv.
dfcategory.to_csv("product_categories.csv", index=False)

# Merge category_id back into Products table
dfprod = dfprod.merge(dfcategory, left_on='category', right_on='category', how='left')

# Remove category column from Products table
dfprod = dfprod.drop(columns= 'category')

# Check that the change is ok
dfprod.head()

# Save changes in products table
dfprod.to_csv("products.csv", index=False)

```

#### Product Categories (5 rows - 5 categories)
After performing EDA on my tables, I realised that normalising the products table was going to be helpful in creating a star schema in Power BI. For that reason, I created the product category table so as to avoid overloading the products table with repeated rows of category names.

### Conclusions on EDA

We can observe that the synthetically generated tables were created successfully. Thanks to observatory functions like df.info, df.head, df.describe, etc. we could determine that there is no missing data, there are not outliers and there are not duplicated values.

## 3. SQL Server Modelling
### 3.1 Database Design

All tables were loaded into a SQL Server database named Logistics.

I chose to create a star schema for my Power BI report. This design supports efficient analytical queries and modelling. For this reason, I create the following views:

```sql

-- Create a purchase orders enriched view containing information of products and delivery times.

USE Logistics
GO;

CREATE OR ALTER VIEW vw_purchase_orders_enriched AS
	SELECT po.order_id,
		po.product_id,
		pr.category_id,
		pr.supplier_id,
		po.order_date,
		po.quantity_ordered,
		po.total_cost,
		d.expected_lead_time_days,
		d.actual_lead_time_days,
		d.expected_delivery_date,
		d.actual_delivery_date,
		d.delay_days,
		CASE 
			WHEN d.delay_days > 0 THEN 'delayed'
			ELSE 'on time' -- Create a boolean column 'on_time'
		END AS on_time
	FROM dbo.purchase_orders po
	LEFT JOIN dbo.delivery_times d ON po.order_id = d.order_id
	LEFT JOIN dbo.products pr ON pr.product_id = po.product_id

-- Create an inventory movements enriched view containing columns from products, category and supplier tables

CREATE OR ALTER VIEW vw_inventory_enriched AS
	SELECT i.movement_id,
		i.product_id,
		p.supplier_id,
		p.category_id,
		i.movement_date,
		CASE WHEN i.movement_type = 'IN' THEN quantity
		WHEN i.movement_type = 'OPENING' THEN quantity
		ELSE -quantity
		END AS quantity -- To simplify further DAX queries, quantity is now shown as positive and negative values, getting rid of the movement type column
	FROM dbo.inventory_movements i
	LEFT JOIN dbo.products p ON i.product_id = p.product_id

```

### 3.2 Stored Procedures

2 distinct stored procedures were implemented:

```sql

-- Create a stored procedure that returns an order summary per supplier when given a date and a supplier name (parameterised filtering)

USE Logistics
GO

CREATE OR ALTER PROC dbo.usp_GetSupplierOrderSummary
	@Supplier NVARCHAR(100) = NULL,
	@Order_date DATE = NULL

AS
BEGIN
	SET NOCOUNT ON;
	SELECT s.supplier_id,
		s.supplier_name,
		s.country,
		COUNT(order_id) AS total_orders,
		ROUND(SUM(total_cost), 2) AS total_spend,
		AVG(quantity_ordered) AS avg_order_size,
		lead_time_days,
		ROUND(on_time_rate, 2) AS on_time_rate,
		freight_cost
	FROM dbo.vw_purchase_orders_enriched po
	LEFT JOIN dbo.suppliers s ON po.supplier_id = s.supplier_id
	WHERE (@Supplier IS NULL OR s.supplier_name LIKE '%' + @Supplier + '%' ) AND 
		(@Order_date IS NULL OR po.order_date >= @Order_date)
	GROUP BY s.supplier_name, s.supplier_id, s.country, on_time_rate, freight_cost, lead_time_days
END

-- Create a stored procedure that returns the running balance of every product when given a date

USE Logistics
GO

CREATE OR ALTER PROC usp_GetInventorySnapshot
	@Date DATE
AS
BEGIN
	SET NOCOUNT ON;

	WITH InventoryCTE AS (
		SELECT product_id,
		movement_date,
		quantity,
		movement_type,
		SUM(
			CASE WHEN movement_type = 'IN' THEN quantity
			 WHEN movement_type = 'OPENING' THEN quantity
			 ELSE -quantity
			 END
			 )
			OVER (PARTITION BY product_id
				ORDER BY movement_date
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
				AS running_balance
		FROM inventory_movements
		)
	SELECT p.product_id,
		p.product_name,
		COALESCE(MAX(i.running_balance), 0) AS quantity_on_hand -- Avoid NULLs if quantity on hand is 0
	FROM dbo.products p
	LEFT JOIN InventoryCTE i ON p.product_id = i.product_id
		AND i.movement_date <= @Date
	GROUP BY p.product_name, p.product_id
END


```

### Conclusions on SQL

2 views and 2 stored procedures were successfully created by using different techniques, such as Common Table Expressions (CTEs), Window functions (running totals), conditional logic, aggregations and grouping, and parameterised procedures.
This demonstrates my knowledge when it comes to reusable SQL logic, while at the same time, a backend analytics capability beyond Power BI.

## 4. Power BI analytics and reporting

### ETL on Power BI

Firstly, I created a connection between Power BI and Microsoft SQL Server in order to import the tables into Power BI. I decided to import them rather than using Direct Query due to the small size of the tables and the fact that we do not require live data updates.

Secondly, I opened up Power Query to transform my tables and made sure they are clean and correct in order to avoid inconsistencies further ahead. However, since the tables were generated synthetically, we do not expect to carry out significative transformations. 

- Rename tables, unable load of unnecessary tables, and group them as fact tables and dimension tables, as seen below:

![alt text](image.png)

- Dropping duplicates on my keys to assure a correct relationship between the tables.
```DAX
  = Table.Distinct(dbo_suppliers, {"supplier_id"}) 
  = Table.Distinct(#"Changed Type", {"product_id"})
  = Table.Distinct(dbo_product_categories, {"category_id"})
```
- None of the tables have errors nor empty values. 

- Creation of a date table using the following DAX:
```DAX
Dim_Date = 
ADDCOLUMNS(
    CALENDAR(DATE(2025, 1, 1), DATE(2026, 01, 31)),
    "Year", YEAR([Date]),
    "Month", FORMAT([Date], "MMM"),
    "Month Number", MONTH([Date]),
    "Year Month", FORMAT([Date], "MM-YYYY"),
    "Day Of Week", FORMAT([Date], "ddd"),
    "Day Of Week Number", WEEKDAY([Date], 2)
)

```

It supports time intelligence, monthly and yearly aggregations, slicers and trend analysis, and lastly, it avoids reliance on implicit date hierarchies.

### 4.1 Model Structure

Power BI uses a clean star schema mirroring the SQL model. The fact tables have been connected to the shared dimensions using single-direction filtering; and all time intelligence analysis is driven by the date dimension table. Key columns have been identified as such; and the date table have been marked as such to override any automatic hierarchical dates in Power BI.

![alt text](image-1.png)

5. DAX Measures \& KPIs
   5.1 Inventory Logic

Because inventory quantities are signed:

SUM(quantity) = net movement

Running balances are calculated via date-aware measures

Closing Stock Balance

Returns inventory as of the selected date context.

Average Daily OUT Movements

Calculates average daily consumption using:

Date-aware iteration

Only negative quantities (OUT)

Days of Inventory Coverage

Indicates how long current stock would last at current consumption rates.

5.2 Performance KPIs

Total Spend

Average Delay (days)

Average On-Time Rate

% Days Below Safety Stock

These KPIs dynamically respond to slicers and cross-filtering.

6. Visual Design \& Interactivity
   6.1 Dashboard Structure

The report is split into logical sections:

Main dashboard – operational overview

Supplier analysis – performance trade-offs

Correlation analysis – relationship exploration

6.2 Visual Techniques Used

Waterfall charts for spend decomposition

Line and area charts for trends

Scatter plots for correlation analysis

Conditional formatting for risk highlighting

Tooltips for contextual detail

Bookmarks for filter control

6.3 Design Decisions

Negative inventory visually highlighted

Safety stock thresholds explicitly marked

Drill-downs limited to avoid over-filtering confusion

Analytical visuals separated from KPI dashboards

7. Key Analytical Takeaways

From a technical perspective, the project demonstrates:

End-to-end ownership of the data lifecycle

Proper dimensional modeling

Correct handling of time-dependent metrics

Awareness of DAX evaluation context pitfalls

Thoughtful visual and interaction design

8. Limitations \& Assumptions

Data is synthetic and illustrative

Safety stock thresholds are assumed

No real operational constraints (MOQ, batching, contracts)

These limitations are explicitly acknowledged to avoid over-interpretation.

9. Potential Enhancements

Reorder point simulation

Forecast-based consumption modeling

Supplier risk scoring

ABC / XYZ inventory segmentation

10. Conclusion

This project demonstrates a production-style analytics workflow, from data generation through modeling to insight communication.

It emphasizes:

Analytical correctness

Modeling discipline

Business relevance

Clear storytelling

