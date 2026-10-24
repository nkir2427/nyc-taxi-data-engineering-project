/*
===============================================================================
Stored Procedure: Load dim_location table (Bronze -> gold)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'gold.dim_location'  tables from the 'bronze.raw_location' table through 
	'silver.dim_location' table.
	Actions Performed:
		-step 1:Truncates Silver table.
		-Step 2: check the incoming data available in gold.location and check if any attributes change in
		- bronze.raw_location ,then we close gold.location records
		-	update;
					is_current ='N'
					end_date =Getdate -1
		- Step 3: INSERT NEW LOCATIONS AND NEW ACTIVE VERSIONS
		--Insert transformed and cleansed new data from bronze into silver table 
		--Insert new active versions of exisisting data for location that were just expired in step 02
		-Step 4 : Delete from gold.dim_location which maching location_id
		-Step 5: Insert data from silver.dim_location to gold.dim_location table
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC gold.sp_load_dim_location;
===============================================================================
*/

CREATE OR ALTER PROCEDURE gold.sp_load_dim_location AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME 
    BEGIN TRY
        
		PRINT '------------------------------------------------';
		PRINT 'Loading Dim_location Table';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.dim_location';
		TRUNCATE TABLE silver.dim_location;


		-- Loading silver.dim_location 
		--maintaining scd type 2 /data which already in gold.dim_location

		PRINT '>> Inserting Data Into: silver.dim_location';
		
		INSERT INTO silver.dim_location (
				location_id,
				borough	,
				zone_name	,
				service_zone	,
				is_current,
				start_date,
				end_date,
				ingested_at
		)
		SELECT  
				b.location_id,
				b.borough	,
				b.zone_name	,
				b.service_zone,
				'N' as is_current,
				b.start_date,
				getdate() -1 as end_date ,
			    b.ingested_at as ingested_at
		FROM bronze.raw_location a
		inner join gold.dim_location b
		on a.location_id =b.location_id
		and b.is_current ='Y'
		AND (
                ISNULL(b.borough, '') <> ISNULL(TRIM(REPLACE(a.borough, '"', '')), '') OR 
                ISNULL(b.zone_name, '') <> ISNULL(TRIM(REPLACE(a.zone_name, '"', '')), '') OR 
                ISNULL(b.service_zone, '') <> ISNULL(TRIM(REPLACE(a.service_zone, '"', '')), '')
              );

		-- Loading silver.dim_location 
		--maintaining scd type 2 /INSERT NEW LOCATIONS AND NEW ACTIVE VERSIONS

		INSERT INTO silver.dim_location (
				location_id,
				borough	,
				zone_name	,
				service_zone	,
				is_current,
				start_date,
				end_date,
				ingested_at
		)		
		SELECT  
				a.location_id,
				TRIM(REPLACE(a.borough, '"', '')) as borough	,
				TRIM(REPLACE(a.zone_name, '"', '')) as zone_name	,
				TRIM(REPLACE(a.service_zone, '"', '')) as service_zone,
				'Y' as is_current,
				cast(getdate()as Date) as start_date,
				cast('9999-01-01'as Date) as end_date ,
			    cast(getdate() as datetime) as  ingested_at
		FROM bronze.raw_location a
		left join gold.dim_location b
		on a.location_id =b.location_id
		and b.is_current= 'Y'
		where b.location_id is null 
		or (
                ISNULL(b.borough, '') <> ISNULL(TRIM(REPLACE(a.borough, '"', '')), '') OR 
                ISNULL(b.zone_name, '') <> ISNULL(TRIM(REPLACE(a.zone_name, '"', '')), '') OR 
                ISNULL(b.service_zone, '') <> ISNULL(TRIM(REPLACE(a.service_zone, '"', '')), '')
              );
		
		--Step 4 : Delete from gold.dim_location which maching location_id
		
		delete from gold.dim_location
		where location_id in (select location_id from  silver.dim_location )
		and  is_current='Y';

		--Step 5: Insert data from silver.dim_location to gold.dim_location table
		insert into gold.dim_location
		select * from silver.dim_location;


		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING Dim_Location Table'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END


