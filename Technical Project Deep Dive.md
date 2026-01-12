# Logistics Analytics Project – Technical Deep Dive

## 1. Overview

This document provides a technical walkthrough of the end-to-end analytics pipeline implemented in this project, consisting in three main steps:

- Synthetic data generation in Python;
- Relational modelling and transformations in SQL Server;
- Analytical modelling, DAX measures, and visualisation logic in Power BI.

The goal was to simulate a realistic logistics environment and demonstrate best practices in data engineering, analytics modelling, and insight generation.

## 2. Data Generation in Python
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

2.3 Core Tables Generated
Suppliers

Each supplier includes:

Lead time (days)

On-time delivery rate

Freight cost

Country of origin

These attributes later enable correlation analysis between reliability, cost, and lead time.

Products

Products were assigned:

A supplier

A product category

A unit cost

This structure supports supplier–product–category rollups in Power BI.

Purchase Orders

Purchase orders were generated with:

Random order dates over a 1-year window

Variable quantities

Calculated total cost

Each order represents a procurement event, not a shipment.

Inventory Movements

Inventory was modeled using signed quantities:

+quantity → stock inflow (IN)

-quantity → stock outflow (OUT)

Key design decisions:

An opening stock level per product was initialized

OUT movements were constrained to available stock

This prevents unrealistic negative inventory at the product level

This approach simplifies:

Running balance calculations

Inventory KPIs in DAX

Delivery Times

Delivery performance was simulated independently from purchase orders using:

Expected lead time from supplier master data

Actual lead time generated via a normal distribution

Calculated delay days

This separation reflects real systems where delivery tracking is operationally distinct from procurement.

3. SQL Server Modeling
   3.1 Database Design

All tables were loaded into a SQL Server database named Logistics.

A star schema was implemented:

Fact Tables

Fact\_Purchase\_Order

Fact\_Inventory

Dimension Tables

Dim\_Supplier

Dim\_Product

Dim\_Product\_Category

Dim\_Date

This design supports efficient analytical queries and Power BI modeling.

3.2 Views (Semantic Layer)

To simplify downstream consumption, enriched views were created.

Examples:

Product views combining supplier and category attributes

Purchase order views enriched with delivery performance

Inventory views joined to product and supplier dimensions

These views:

Encapsulate join logic

Reduce complexity in Power BI

Act as a semantic layer between raw data and reporting

3.3 Stored Procedures

Stored procedures were implemented to:

Retrieve supplier performance summaries

Support parameterized filtering (supplier, date)

This demonstrates:

Reusable SQL logic

Backend analytics capability beyond Power BI

3.4 SQL Techniques Used

Common Table Expressions (CTEs)

Window functions (running totals)

Conditional logic

Aggregations and grouping

Parameterized procedures

4. Power BI Data Model
   4.1 Model Structure

Power BI uses a clean star schema mirroring the SQL model.

Key relationships:

Fact tables connect to shared dimensions

Single-direction filtering

Date dimension drives all time intelligence

Redundant descriptive columns were removed from fact tables to avoid ambiguity and duplication.

4.2 Date Dimension

A dedicated date table was created to support:

Time intelligence

Monthly and yearly aggregation

Slicers and trend analysis

This avoids reliance on implicit date hierarchies.

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

