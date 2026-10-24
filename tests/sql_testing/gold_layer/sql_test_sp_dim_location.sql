
/*******************************************************************************
 * NYC TAXI PIPELINE: SCD TYPE 2 TESTING SUITE (dim_location)
 *******************************************************************************/

-- 1. INITIAL LOAD TEST
EXEC gold.sp_load_dim_location;

SELECT COUNT(*) AS initial_load_count 
FROM gold.dim_location 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);


-- 2. RERUN LOAD TEST (Idempotency Check)
EXEC gold.sp_load_dim_location;

SELECT COUNT(*) AS rerun_count 
FROM gold.dim_location 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);


-- 3. CHANGE DATA RECORD TEST (Update / Versioning Test)
UPDATE bronze.raw_location 
SET borough = 'king'
WHERE borough = 'queens' AND zone_name = 'Jamaica Bay';

EXEC gold.sp_load_dim_location;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_location;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_location;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_location;

-- Check historical versioning for location_id = 2 (Should show old 'Y'->'N' and new 'Y')
SELECT * FROM gold.dim_location WHERE location_id = 2;


-- 4. ADDING NEW RECORD TEST
INSERT INTO bronze.raw_location (location_id, borough, zone_name, service_zone) 
VALUES (265, 'N/A', 'Outside of NYC', 'N/A');

EXEC gold.sp_load_dim_location;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_location;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_location;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_location 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);

-- Verify newly added location
SELECT * FROM gold.dim_location WHERE location_id = 265;


-- 5. REMOVING ONE RECORD TEST (Source Deletion Handling)
DELETE FROM bronze.raw_location 
WHERE location_id = 2;

EXEC gold.sp_load_dim_location;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_location;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_location;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_location 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);

-- Verify location 2 history remains untouched in Gold
SELECT * FROM gold.dim_location WHERE location_id = 2;


-- 6. ADD SAME RECORD AGAIN TEST (Re-insertion / Re-activation Test)
INSERT INTO bronze.raw_location (location_id, borough, zone_name, service_zone) 
VALUES (2, 'queens', 'Jamaica Bay', 'Boro Zone');

EXEC gold.sp_load_dim_location;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_location;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_location;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_location 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);

-- Verify location 2 gets a new active version created
SELECT * FROM gold.dim_location WHERE location_id = 2;