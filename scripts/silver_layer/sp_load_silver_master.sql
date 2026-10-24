/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.sp_load_silver_master;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.sp_load_silver_master AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading Dim Tables';
		PRINT '------------------------------------------------';

		

				-- Loading silver.dim_rate_code
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.dim_rate_code';
		TRUNCATE TABLE silver.dim_rate_code;
		PRINT '>> Inserting Data Into: silver.dim_rate_code';
		INSERT INTO silver.dim_rate_code (
			rate_code_id,
			rate_code_desc,
			ingested_at
		)
		SELECT
			rate_code_id,
			TRIM(rate_code_desc) AS rate_code_desc,
			Getdate()  as ingested_at
		FROM bronze.raw_rate_code;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        

        -- Loading dim_payment
        SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.dim_payment';
		TRUNCATE TABLE silver.dim_payment;
		PRINT '>> Inserting Data Into: silver.dim_payment';
		INSERT INTO silver.dim_payment (
			payment_type_id,
			payment_type_desc,
			ingested_at
		)
		SELECT
		payment_type_id,
		TRIM(payment_type_desc) AS payment_type_desc,
		GETDATE() as ingested_at
			FROM bronze.raw_payment;
	    SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

		
		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END


--EXEC Silver.sp_load_silver_master