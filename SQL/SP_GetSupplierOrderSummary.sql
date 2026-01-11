-- Create a stored procedure that returns an order summary per supplier when given a date and a supplier name

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

EXEC dbo.usp_GetSupplierOrderSummary @Supplier = 'Cohen'