/*
========================================================
BRONZE LOAD PROCEDURE
========================================================
Purpose:
- Full load of raw dim data into Bronze tables.
- Truncates existing data before loading.
- Uses  INSERT to load CSV files due to file size is small.
- Tracks individual and total load duration.
- TRY...CATCH handles loading errors.

Execution:
EXEC bronze.load_bronze;
========================================================
*/



CREATE OR ALTER PROCEDURE bronze.load_bronze_master_data AS
BEGIN

	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
	BEGIN TRY
		SET @batch_start_time = GETDATE();


		PRINT '================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading master Tables';
		PRINT '------------------------------------------------';
		--bulk insert the data from csv files into the tables
		--dim TABLES
		--TABLE NAME: bronze.raw_vendor
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.raw_vendor';

		TRUNCATE TABLE bronze.raw_vendor;
		PRINT '>> INSERTING DATA into: bronze.raw_vendor';

		BULK INSERT bronze.raw_vendor
		from 'C:\Users\User\nyc-taxi-data-engineering-project\data\master_data\raw_vendor.csv'
		WITH (
			FIRSTROW =2 ,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
		
		
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.raw_rate_code';

		--TABLE NAME: bronze.raw_rate_code
		TRUNCATE TABLE bronze.raw_rate_code;
		PRINT '>> INSERTING DATA into: bronze.raw_rate_code';

		BULK INSERT bronze.raw_rate_code
		from 'C:\Users\User\nyc-taxi-data-engineering-project\data\master_data\raw_rate_code.csv'
		WITH (
			FIRSTROW =2 ,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.raw_location';

		--TABLE NAME: bronze.raw_location
		TRUNCATE TABLE bronze.raw_location;
		PRINT '>> INSERTING DATA into: bronze.raw_location';

		BULK INSERT bronze.raw_location
		from 'C:\Users\User\nyc-taxi-data-engineering-project\data\master_data\taxi_zone_lookup.csv'
		WITH (
			FIRSTROW =2 ,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table: bronze.raw_payment';

		--TABLE NAME: bronze.raw_payment
		TRUNCATE TABLE bronze.raw_payment;
		PRINT '>> INSERTING DATA into: bronze.raw_payment';

		BULK INSERT bronze.raw_payment
		from 'C:\Users\User\nyc-taxi-data-engineering-project\data\master_data\raw_payment.csv'
		WITH (
			FIRSTROW =2 ,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '>> -------------';
		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='

	END TRY
	BEGIN CATCH		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH		

END
;

EXEC bronze.load_bronze_master_data