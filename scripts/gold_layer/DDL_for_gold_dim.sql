use nyc_taxi_data;
drop table gold.dim_vendor
create table gold.dim_vendor
( 
Vendor_key INT IDENTITY(1,1) NOT NULL,
vendor_id	INT,
vendor_name	VARCHAR(250),
is_current varchar(1),
start_date date,
end_date date,
ingested_at	Datetime
);

create table gold.dim_datetime	
(datetime_id	INT,
full_datetime	DATETIME2,
date_key	DATE,
month_id INT,
year	INT,
month	INT,
day	INT,
hour	INT,
day_of_week	VARCHAR(15),
is_weekend	BIT
);


drop table gold.dim_rate_code;
create table gold.dim_rate_code	
(ratecode_key int  IDENTITY(1,1) NOT NULL,
rate_code_id	INT,
rate_code_desc	VARCHAR(25),
ingested_at	Datetime
);

drop table gold.dim_location
create table gold.dim_location	
(location_key int  IDENTITY(1,1) NOT NULL,
location_id	INT,
borough	NVARCHAR(50),
zone_name	NVARCHAR(100),
service_zone	NVARCHAR(50),
is_current varchar(1),
start_date date,
END_DATE date,
ingested_at	Datetime
);

drop table gold.dim_payment;
create table gold.dim_payment	
(payment_key int  IDENTITY(1,1) NOT NULL,
payment_type_id	INT,
payment_type_desc	VARCHAR(25),
ingested_at	Datetime
);