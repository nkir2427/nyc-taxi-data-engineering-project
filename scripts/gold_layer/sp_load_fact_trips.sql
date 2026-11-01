
/*
===============================================================================
Stored Procedure: Load Fact Trips Table (Bronze -> Silver -> Gold)
===============================================================================

Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process
    to populate the gold.fact_trips table using NYC Yellow Taxi trip data
    from bronze.yellow_tripdata through silver.fact_trips.

Actions Performed:

    Step 1: Truncate Silver Fact Table
        - Truncate silver.fact_trips before loading new transformed data.
        - Ensure the Silver staging table is ready for the current ETL run.

    Step 2: Extract and Transform Bronze Data
        - Extract taxi trip records from bronze.yellow_tripdata.
        - Perform LEFT JOIN lookups against Gold dimension tables:
            * gold.dim_vendor
            * gold.dim_datetime (pickup and dropoff)
            * gold.dim_location (pickup and dropoff)
            * gold.dim_rate_code
            * gold.dim_payment
        - Retrieve corresponding surrogate dimension keys.
        - Derive month_id from the pickup datetime dimension.
        - Preserve trip measures and applicable surcharge amounts.
        - Assign the current ETL ingestion timestamp.

    Step 3: Load Transformed Data into Silver
        - Insert transformed records into silver.fact_trips.
        - Preserve resolved dimension keys and transaction measures.
        - Retain NULL dimension keys where lookups are unsuccessful
          for subsequent data-quality validation.

    Step 4: Check for Existing Records in Gold
        - Compare Silver records against gold.fact_trips.
        - Identify potential duplicate records using the configured
          source-record uniqueness criteria.
        - Exclude records that have already been loaded.

    Step 5: Insert New Records into Gold
        - Insert eligible new records from silver.fact_trips
          into gold.fact_trips.
        - Allow SQL Server to generate the trip_id automatically
          using the IDENTITY property.
        - Avoid duplicate records during repeated ETL executions.

    Step 6: Complete ETL Execution
        - Finalize the fact table loading operation.
        - Make newly loaded trip data available for reporting
          and analytical queries.

Dependencies:
    - bronze.yellow_tripdata
    - silver.fact_trips
    - gold.fact_trips
    - gold.dim_vendor
    - gold.dim_datetime
    - gold.dim_location
    - gold.dim_rate_code
    - gold.dim_payment

Important Notes:
    - Dimension tables should be populated before loading fact trips.
    - Unmatched dimension keys require an approved handling strategy.
    - The source-record uniqueness rule must be validated.
    - trip_id is generated automatically and must not be inserted
      explicitly.
    - ETL ingestion timestamps are generated using GETDATE().

Parameters:
    None.
    This stored procedure does not accept any input parameters.

Usage Example:
    EXEC gold.sp_load_fact_trips;

===============================================================================
*/


CREATE OR ALTER PROCEDURE gold.sp_load_fact_trips AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME 
    BEGIN TRY
        
		PRINT '------------------------------------------------';
		PRINT 'Loading fact_trips Table';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.fact_trips';
		TRUNCATE TABLE silver.fact_trips;


		-- Loading silver.fact_trips 

		PRINT '>> Inserting Data Into: silver.fact_trips';

            insert into silver.fact_trips
            (month_id
             ,vendor_key
             ,pickup_datetime_id
             ,dropoff_datetime_id
             ,pu_location_key
             ,do_location_key
             ,rate_code_key
             ,payment_key
             ,passenger_count
             ,trip_distance
             ,store_and_fwd_flag
             ,fare_amount
             ,extra
             ,mta_tax
             ,tip_amount
             ,tolls_amount
             ,improvement_surcharge
             ,total_amount
             ,congestion_surcharge
             ,airport_fee
             ,ingested_at)

                select 
                 dim_date.month_id as month_id
                ,dim_vndr.Vendor_key as vendor_key
                ,dim_date.datetime_id as pickup_datetime_id
                ,dim_date_drop.datetime_id as dropoff_datetime_id
                ,dim_loc.location_key as pu_location_key
                ,dim_loc1.location_key as do_location_key 
                ,dim_rate.ratecode_key as rate_code_key
                ,dim_payment.payment_key as payment_key
                ,lndp_trips.passenger_count
                ,lndp_trips.trip_distance
                ,lndp_trips.store_and_fwd_flag
                ,lndp_trips.fare_amount
                ,lndp_trips.extra
                ,lndp_trips.mta_tax
                ,lndp_trips.tip_amount
                ,lndp_trips.tolls_amount
                ,lndp_trips.improvement_surcharge
                ,lndp_trips.total_amount
                ,lndp_trips.congestion_surcharge
                ,lndp_trips.airport_fee
                --,lndp_trips.source_file
                ,Getdate() as ingested_at
                 from bronze.yellow_tripdata lndp_trips
                left join gold.dim_vendor dim_vndr
                on lndp_trips.VendorID =dim_vndr.vendor_id
                left join gold.dim_datetime dim_date
                on FORMAT(CAST(lndp_trips.tpep_pickup_datetime AS datetime2),'yyyy-MM-dd HH')=FORMAT(CAST(dim_date.full_datetime AS datetime2),'yyyy-MM-dd HH')
                left join gold.dim_datetime dim_date_drop
                on FORMAT(CAST(lndp_trips.tpep_dropoff_datetime AS datetime2),'yyyy-MM-dd HH')=FORMAT(CAST(dim_date_drop.full_datetime AS datetime2),'yyyy-MM-dd HH')
                left join gold.dim_location dim_loc
                on lndp_trips.PULocationID=dim_loc.location_id
                left join gold.dim_location dim_loc1
                on lndp_trips.DOLocationID=dim_loc1.location_id 
                left join gold.dim_rate_code dim_rate
                on lndp_trips.ratecodeid=dim_rate.rate_code_id
                left join gold.dim_payment dim_payment
                on lndp_trips.payment_type=dim_payment.payment_type_id
                ;

		-- Loading gold.fact_trips 

		PRINT '>> Inserting Data Into: gold.fact_trips';

        insert into gold.fact_trips 
        select * from silver.fact_trips silver_trips
        WHERE NOT EXISTS (
            SELECT 1
            FROM gold.fact_trips gold_trips
            WHERE gold_trips.month_id = silver_trips.month_id
              AND gold_trips.vendor_key = silver_trips.vendor_key
              AND gold_trips.pickup_datetime_id = silver_trips.pickup_datetime_id
              AND gold_trips.dropoff_datetime_id = silver_trips.dropoff_datetime_id
              AND gold_trips.pu_location_key = silver_trips.pu_location_key
              AND gold_trips.do_location_key =silver_trips.do_location_key
              and gold_trips.rate_code_key=silver_trips.rate_code_key
              and gold_trips.payment_key=silver_trips.payment_key
        );
		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';
		
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING fact_trips Table'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END




    EXEC gold.sp_load_fact_trips;
