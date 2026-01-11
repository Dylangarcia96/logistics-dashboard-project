-- Create a purchase orders enriched view containing columns from supplier and category tables 

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
			ELSE 'on time'
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
		END AS quantity
	FROM dbo.inventory_movements i
	LEFT JOIN dbo.products p ON i.product_id = p.product_id


