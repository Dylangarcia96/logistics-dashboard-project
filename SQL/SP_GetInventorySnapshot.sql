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
		COALESCE(MAX(i.running_balance), 0) AS quantity_on_hand
	FROM dbo.products p
	LEFT JOIN InventoryCTE i ON p.product_id = i.product_id
		AND i.movement_date <= @Date
	GROUP BY p.product_name, p.product_id
END

EXEC dbo.usp_GetInventorySnapshot @Date = '11-30-2025'

