
-- 1. Create the gold schema if it doesn't exist yet
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA [gold]');
GO

-- 2. Create Partition Function on month_id (INT)
-- Example A: If month_id is YYYYMM (e.g., 202601 to 202612)
CREATE PARTITION FUNCTION pf_MonthId (INT)
AS RANGE RIGHT FOR VALUES (
    201601, 201602, 201603, 201604, 201605, 201606, 
    201607, 201608, 201609, 201610, 201611, 201612
);
-- (Note: If your month_id is just 1 to 12, use: VALUES (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12))
GO

-- 3. Create Partition Scheme mapping all partitions to PRIMARY filegroup
CREATE PARTITION SCHEME ps_MonthId
AS PARTITION pf_MonthId
ALL TO ([PRIMARY]);
GO

-- 4. Create the partitioned table
CREATE TABLE gold.fact_trips (
    month_id                INT NOT NULL,
    trip_id                 INT NOT NULL,
    vendor_id               INT,
    pickup_datetime_id      INT,
    dropoff_datetime_id     INT,
    pu_location_id          INT,
    do_location_id          INT,
    rate_code_id            INT,
    payment_type_id         INT,
    passenger_count         INT,
    trip_distance           DECIMAL(6,3),
    store_and_fwd_flag      NVARCHAR(50),
    fare_amount             DECIMAL(6,3),
    extra                   DECIMAL(6,3),
    mta_tax                 DECIMAL(6,3),
    tip_amount              DECIMAL(6,3),
    tolls_amount            DECIMAL(6,3),
    improvement_surcharge   DECIMAL(6,3),
    total_amount            DECIMAL(6,3),
    congestion_surcharge    DECIMAL(6,3),
    airport_fee             DECIMAL(6,3),
    source_file             NVARCHAR(255),
    ingested_at             DATE,

    -- Optional: If you want a Primary Key, month_id MUST be included in it:
    CONSTRAINT PK_fact_trips PRIMARY KEY CLUSTERED (month_id, trip_id)
) 
ON ps_MonthId(month_id); -- <-- Attaches table to the partition scheme
GO





















create table gold.fact_trips	
(month_id,
trip_id	INT
vendor_id	INT
pickup_datetime_id	INT
dropoff_datetime_id	INT
pu_location_id	INT
do_location_id	INT
rate_code_id	INT
payment_type_id	INT
passenger_count	INT
trip_distance	DECIMAL(6,3)
store_and_fwd_flag	NVARCHAR(50)
fare_amount	DECIMAL(6,3)
extra	DECIMAL(6,3)
mta_tax	DECIMAL(6,3)
tip_amount	DECIMAL(6,3)
tolls_amount	DECIMAL(6,3)
improvement_surcharge	DECIMAL(6,3)
total_amount	DECIMAL(6,3)
congestion_surcharge	DECIMAL(6,3)
airport_fee	DECIMAL(6,3),
source_file	NVARCHAR(255)
ingested_at	Date
)
