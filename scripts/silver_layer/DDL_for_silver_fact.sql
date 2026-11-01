
drop table silver.fact_trips


CREATE TABLE silver.fact_trips (
    month_id                INT NOT NULL,
    trip_id                 INT IDENTITY(1,1)  PRIMARY KEY,
    vendor_key               INT,
    pickup_datetime_id      INT,
    dropoff_datetime_id     INT,
    pu_location_key          INT,
    do_location_key          INT,
    rate_code_key            INT,
    payment_key          INT,
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
    ingested_at             DATE,
) 