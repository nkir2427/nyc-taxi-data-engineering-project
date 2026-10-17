use nyc_taxi_data;


CREATE OR ALTER PROCEDURE bronze.bronze_load_yellow_taxi_csv
    @FilePath NVARCHAR(500),
    @SchemaName NVARCHAR(128) = N'bronze',
    @ViewName   NVARCHAR(128) = N'view_yellow_tripdata_staging',
    @ColumnList NVARCHAR(MAX) = N'VendorID,tpep_pickup_datetime,tpep_dropoff_datetime,passenger_count,trip_distance,RatecodeID,store_and_fwd_flag,PULocationID,DOLocationID,payment_type,fare_amount,extra,mta_tax,tip_amount,tolls_amount,improvement_surcharge,total_amount,congestion_surcharge,airport_fee'
AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME 
    BEGIN TRY
        SET @start_time = GETDATE();
        SET NOCOUNT ON;

        DECLARE @FileName NVARCHAR(255);
        DECLARE @Sql NVARCHAR(MAX);
        DECLARE @Sql_truncate NVARCHAR(MAX);
        DECLARE @Sql_view NVARCHAR(MAX);


        SET @FileName =
            RIGHT(@FilePath, CHARINDEX('\', REVERSE(@FilePath) + '\') - 1);
        SET @Sql_truncate=N'  TRUNCATE TABLE bronze.yellow_tripdata;';

    -- Build the CREATE OR ALTER VIEW statement dynamically
        SET @Sql_view = N'
            CREATE OR ALTER VIEW ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@ViewName) + N'
            AS
            SELECT ' + @ColumnList + N'
            FROM ' + QUOTENAME(@SchemaName) + N'.yellow_tripdata;
        ';

        EXEC sys.sp_executesql @Sql_view;
        PRINT 'Step 0: view create';

        PRINT 'View ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@ViewName) + ' created/altered successfully.';


        SET @Sql = N'
            BULK INSERT bronze.view_yellow_tripdata_staging
            FROM ''' + REPLACE(@FilePath, '''', '''''') + N'''
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                TABLOCK,
                MAXERRORS = 10
            );';


        PRINT 'Step 1: Starting truncate';

        EXEC sys.sp_executesql @Sql_truncate;
        PRINT 'Step 1: complete truncate';
        PRINT 'Step 2: Starting insert';

        EXEC sys.sp_executesql @Sql;

        PRINT 'Step 1: complete insert';
     
        -- Populate source metadata
        UPDATE bronze.yellow_tripdata
        SET source_file = @FileName,
        ingested_at =GETDATE()
        WHERE source_file IS NULL;
    

        PRINT 'Processed file: ' + @FileName;

        SET @end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @End_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='

    END TRY
	BEGIN CATCH		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH	
END;






exec bronze.bronze_load_yellow_taxi_csv
    @filepath='C:\Users\User\nyc-taxi-data-engineering-project\data\processed\yellow_tripdata__2016-01_sample.csv';



