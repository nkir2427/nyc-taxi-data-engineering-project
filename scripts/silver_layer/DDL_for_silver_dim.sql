use nyc_taxi_data;
drop table silver.dim_vendor
create table silver.dim_vendor
( 
vendor_id	INT,
vendor_name	VARCHAR(250),
is_current varchar(1),
start_date date,
end_date date,
ingested_at	Datetime
);

drop table silver.dim_rate_code
create table silver.dim_rate_code	
(rate_code_id	INT,
rate_code_desc	VARCHAR(25),
ingested_at	Datetime
);

drop table silver.dim_location
create table silver.dim_location	
(location_id int,
borough	varchar(50),
zone_name varchar(100)	,
service_zone varchar(50),
is_current varchar(1),
start_date date,
end_date date,
ingested_at	 Datetime
);

drop table silver.dim_payment	
create table silver.dim_payment	
(payment_type_id	INT,
payment_type_desc	VARCHAR(25),
ingested_at	Datetime
);