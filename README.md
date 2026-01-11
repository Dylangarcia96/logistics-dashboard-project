# Logistics Performance Analytics Dashboard



## Project Overview



### Purpose:



This project simulates a real-world logistics environment using synthetic data and demonstrates an end-to-end analytics workflow.

The main focus is to analyse supplier performance, purchasing behaviour, and inventory dynamics to support better procurement and inventory planning decisions.



### Tools Used:



* Python (synthetic data generation)



* SQL Server (data modelling, views, stored procedures)



* Power BI (data modelling, DAX, visual reports)



## Business Problem



Logistics teams often experience difficulties with:



* Understanding where spend is concentrated among suppliers



* Evaluating supplier reliability



* Finding an accurate balance between inventory availability and overstocking



* Identifying drivers of total spend and delays



This project addresses those challenges by combining purchasing, supplier, delivery, and inventory movement data into a unified analytical model.



## Data Sources



The dataset was synthetically generated in Python to mimic realistic logistics operations.



### Core Tables



* Suppliers: supplier details, lead time, on-time rate, freight cost



* Products: product catalogue with category and supplier assignment



* Purchase Orders: order quantities, dates, and total cost



* Inventory Movements: IN / OUT movements with signed quantities



* Delivery Times: expected vs. actual delivery performance



* Date Dimension: calendar table for time intelligence



## Data Modelling and Transformations



1. Python



	* Generated reproducible synthetic data using numpy, pandas, and faker



	* Implemented opening stock logic to prevent unrealistic negative inventory



	* Simulated delivery delays using probabilistic distributions



2. SQL Server



Created a star schema with:



	* Fact tables: Fact\_Purchase\_Order, Fact\_Inventory



	* Dimension tables: Supplier, Product, Category, Date



Built enriched views to simplify reporting using CTEs, Window Functions and Stored procedures for parameterised analyses.


3. Power BI



	* Implemented a clean dimensional model



	* Divided the report into a main diagnostic page and successive analytical pages



	* Created the following Key KPIs \& Metrics:



		* Total Spend



		* Average Delay (days)



		* Average On-Time Rate



		* Closing Stock Balance



		* Days of Inventory Coverage



		* % Days Below Safety Stock



These KPIs dynamically respond to date, supplier, product, and category filters and drill downs from other charts



## Key Insights



### Spend and Demand



Total spend is relatively well distributed across suppliers, reducing dependency risk. However, monthly spend shows high variability, indicating opportunities 	for better demand planning and purchase smoothing.



### Inventory



Total inventory coverage exceeds 300 days, suggesting significant overstocking. As a consequence, holding costs increase, as well as warehouse space usage and obsolescence risk.

Frequent inventory fluctuations highlight potential misalignment between purchasing and consumption.



### Supplier Performance



Delayed orders are common, though the average delay remains modest (≈ 2–4 days).

There is no meaningful correlation between freight cost and on-time delivery, suggesting higher freight spend does not guarantee reliability.

A negative correlation exists between lead time and on-time rate — shorter lead times improve delivery reliability.



### Spend Drivers



Most suppliers cluster around a similar average order size. However, order size alone does not drive total spend.

On the contrary, number of orders is the primary driver of total spend, as evidenced by larger bubbles corresponding to higher spend.



## Limitations



1. Data is synthetically generated and does not represent a specific real company.
   
2. Inventory movements are simulated and may not reflect operational constraints such as batch sizes or reorder policies.
   
3. Safety stock thresholds are assumed for demonstration purposes.



## Next Steps and Enhancements



* Introduce reorder point logic and automatic replenishment simulation



* Add forecasting for demand and inventory consumption



* Segment suppliers by risk profile (cost vs. reliability trade-off)



* Incorporate ABC / XYZ inventory classification
