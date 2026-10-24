/*
===============================================================================
Stored Procedure: Load dim_vendor table (Bronze -> gold)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'gold.dim_vendor'  tables from the 'bronze.raw_vendor' table through 
	'silver.dim_vendor' table.
	Actions Performed:
		-step 1:Truncates Silver table.
		-Step 2: check the incoming data available in gold.dim_vendor and check if any attributes change in
		- bronze.raw_vendor ,then we close gold.dim_vendor records
		-	update;
					is_current ='N'
					end_date =Getdate -1
		- Step 3: INSERT NEW dim_vendorS AND NEW ACTIVE VERSIONS
		--Insert transformed and cleansed new data from bronze into silver table 
		--Insert new active versions of exisisting data for dim_vendor that were just expired in step 02
		-Step 4 : Delete from gold.dim_vendor which maching dim_vendor_id
		-Step 5: Insert data from silver.dim_vendor to gold.dim_vendor table
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC gold.sp_load_dim_vendor;
===============================================================================
*/

CREATE OR ALTER PROCEDURE gold.sp_load_dim_vendor AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME 
    BEGIN TRY
        
		PRINT '------------------------------------------------';
		PRINT 'Loading dim_vendor Table';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.dim_vendor';
		TRUNCATE TABLE silver.dim_vendor;


		-- Loading silver.dim_vendor 
		--maintaining scd type 2 /data which already in gold.dim_vendor

		PRINT '>> Inserting Data Into: silver.dim_vendor';
		
		INSERT INTO silver.dim_vendor (
				vendor_id, 
				vendor_name, 
				is_current,
				start_date,
				end_date,
				ingested_at 
		)
		SELECT  
				b.vendor_id,
				b.vendor_name	,
				'N' as is_current,
				b.start_date,
				getdate() -1 as end_date ,
			    b.ingested_at as ingested_at
		FROM bronze.raw_vendor a
		inner join gold.dim_vendor b
		on cast(a.vendor_id as int) =b.vendor_id
		and b.is_current ='Y'
		AND ISNULL(b.vendor_name, '') <> ISNULL(TRIM(REPLACE(a.vendor_name, '"', '')), '');






		-- Loading silver.dim_vendor 
		--maintaining scd type 2 /INSERT NEW dim_vendorS AND NEW ACTIVE VERSIONS

		INSERT INTO silver.dim_vendor (
				vendor_id, 
				vendor_name, 
				is_current,
				start_date,
				end_date,
				ingested_at
		)		
		SELECT  
			cast(a.vendor_id as int) as vendor_id,
			TRIM(REPLACE(a.vendor_name, '"', '')) AS vendor_name,
			'Y' as is_current,
			Getdate() as start_date,
			case when b.end_date is not null then getdate() -1
				     else '9999-01-01' end as end_date ,
			Getdate() as ingested_at
		FROM bronze.raw_vendor a
		left join gold.dim_vendor b
		on cast(a.vendor_id as int) =b.vendor_id
		and b.is_current= 'Y'
		where b.vendor_id is null
		or ISNULL(b.vendor_name, '') <> ISNULL(TRIM(REPLACE(a.vendor_name, '"', '')), '')



		
		--Step 4 : Delete from gold.dim_vendor which maching dim_vendor_id
		
		delete from gold.dim_vendor
		where vendor_id in (select vendor_id from  silver.dim_vendor)
		and is_current= 'Y';
		--Step 5: Insert data from silver.dim_vendor to gold.dim_vendor table
		insert into gold.dim_vendor
		select * from silver.dim_vendor;


		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING dim_vendor Table'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END


--EXEC gold.sp_load_dim_vendor

