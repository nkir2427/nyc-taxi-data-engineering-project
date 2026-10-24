/*
===============================================================================
Stored Procedure: Load gold Layer (gold -> Gold)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'gold' schema one time load tables from the 'gold' schema.
	Actions Performed:
		- Truncates gold tables.
		- Inserts transformed and cleansed data from gold into gold tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC gold.sp_load_gold_master;
===============================================================================
*/

CREATE OR ALTER PROCEDURE gold.sp_load_gold_master AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading gold Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading Dim Tables';
		PRINT '------------------------------------------------';

		

				-- Loading gold.dim_rate_code
        SET @start_time = GETDATE();
		---- 1. Safely clear out the old data in the SCD Type 1 table
		PRINT '>> Truncating Table: gold.dim_rate_code';
		TRUNCATE TABLE gold.dim_rate_code;
		---- 2. Freshly insert all current records from the Silver/Clean layer
		PRINT '>> Inserting Data Into: gold.dim_rate_code';
		INSERT INTO gold.dim_rate_code (
			rate_code_id,
			rate_code_desc,
			ingested_at
		)
		SELECT
			rate_code_id,
			rate_code_desc,
			ingested_at
		FROM silver.dim_rate_code;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        

        -- Loading dim_payment
        SET @start_time = GETDATE();
		---- 1. Safely clear out the old data in the SCD Type 1 table
		PRINT '>> Truncating Table: gold.dim_payment';
		TRUNCATE TABLE gold.dim_payment;
		---- 2. Freshly insert all current records from the Silver/Clean layer
		PRINT '>> Inserting Data Into: gold.dim_payment';
		INSERT INTO gold.dim_payment (
			payment_type_id,
			payment_type_desc,
			ingested_at
		)
		SELECT
		payment_type_id,
		payment_type_desc,
		ingested_at
			FROM silver.dim_payment;
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		
		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading gold Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING gold LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END


EXEC gold.sp_load_gold_master