use nyc_taxi_data;



-- DDL FOR yellow_tripdata IN BRONZE LAYER

if object_id ('bronze.yellow_tripdata', 'U' ) is not null 
	drop table bronze.yellow_tripdata ;

Go

create table bronze.yellow_tripdata
(
VendorID	INT,
tpep_pickup_datetime	Date,
tpep_dropoff_datetime	Date,
passenger_count	INT,
trip_distance	DECIMAL(6,3),
RatecodeID	INT,
store_and_fwd_flag	NVARCHAR(50),
PULocationID	INT,
DOLocationID	INT,
payment_type	INT,
fare_amount DECIMAL(6,3),
extra	DECIMAL(6,3),
mta_tax	DECIMAL(6,3),
tip_amount	DECIMAL(6,3),
tolls_amount	DECIMAL(6,3),
improvement_surcharge DECIMAL(6,3)	,
total_amount	DECIMAL(6,3),
congestion_surcharge	DECIMAL(6,3),
airport_fee DECIMAL(6,3)
);
