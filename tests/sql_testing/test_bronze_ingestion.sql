use nyc_taxi_data;

--check the data in the table 

select * from bronze.yellow_tripdata;


-- 1.Check total rows loaded in Bronze
SELECT COUNT(*) AS bronze_row_count 
FROM bronze.yellow_tripdata;
--file row count: 5000
--table row_count: 5000

--all rows loaded into the table


---

---2. Null Checks on Essential Structural Keys
--Even in Bronze (where some messy data is expected), primary routing fields, timestamps, and identifiers should not be completely null.


SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN tpep_pickup_datetime IS NULL THEN 1 ELSE 0 END) AS null_pickups,
    SUM(CASE WHEN tpep_dropoff_datetime IS NULL THEN 1 ELSE 0 END) AS null_dropoffs,
    SUM(CASE WHEN trip_distance IS NULL THEN 1 ELSE 0 END) AS null_distances,
    SUM(CASE WHEN fare_amount IS NULL THEN 1 ELSE 0 END) AS null_fares
FROM bronze.yellow_tripdata;

--test passed 

---3.Date / Time Range Sanity Check

SELECT 
    MIN(tpep_pickup_datetime) AS earliest_pickup,
    MAX(tpep_pickup_datetime) AS latest_pickup,
    MIN(tpep_dropoff_datetime) AS earliest_dropoff,
    MAX(tpep_dropoff_datetime) AS latest_dropoff
FROM bronze.yellow_tripdata;

--test passed

--4 Basic Data Profile & Boundary Checks (Negative or Zero Values)

SELECT 
    COUNT(*) AS total_trips,
    COUNT(CASE WHEN fare_amount <= 0 THEN 1 END) AS non_positive_fares,
    COUNT(CASE WHEN trip_distance = 0 THEN 1 END) AS zero_distance_trips,
    COUNT(CASE WHEN passenger_count = 0 THEN 1 END) AS zero_passenger_trips,
    MAX(fare_amount) AS max_fare,
    MAX(trip_distance) AS max_distance
FROM bronze.yellow_tripdata;

--have to do some adjustment /transformation to load silver layer

--5.Ingestion Metadata Audit

SELECT 
    COUNT(*) AS total_rows,
    COUNT(ingested_at) AS non_null_timestamps,
    COUNT(DISTINCT source_file) AS distinct_source_files
FROM bronze.yellow_tripdata;