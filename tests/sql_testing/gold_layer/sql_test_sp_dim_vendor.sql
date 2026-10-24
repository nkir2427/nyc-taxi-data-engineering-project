
/*******************************************************************************
 * NYC TAXI PIPELINE: SCD TYPE 2 TESTING SUITE (dim_vendor)
 *******************************************************************************/

-- 1. INITIAL LOAD TEST
EXEC gold.sp_load_dim_vendor;

SELECT COUNT(*) AS initial_load_count 
FROM gold.dim_vendor 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);


-- 2. RERUN LOAD TEST (Idempotency Check)
EXEC gold.sp_load_dim_vendor;

SELECT COUNT(*) AS rerun_count 
FROM gold.dim_vendor 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);


-- 3. CHANGE DATA RECORD TEST (Update / Versioning Test)
UPDATE bronze.raw_vendor 
SET vendor_name = 'Helix1'
WHERE vendor_id = '7' ;

EXEC gold.sp_load_dim_vendor;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_vendor;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_vendor;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_vendor;

-- Check historical versioning for location_id = 2 (Should show old 'Y'->'N' and new 'Y')
SELECT * FROM gold.dim_vendor WHERE vendor_id = 7;


-- 4. ADDING NEW RECORD TEST
INSERT INTO bronze.raw_vendor (vendor_id, vendor_name) 
VALUES (10, 'Abans');

EXEC gold.sp_load_dim_vendor;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_vendor;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_vendor;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_vendor 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);

-- Verify newly added location
SELECT * FROM gold.dim_vendor WHERE vendor_id = 10;


-- 5. REMOVING ONE RECORD TEST (Source Deletion Handling)
DELETE FROM bronze.raw_vendor 
WHERE vendor_id = 10;

EXEC gold.sp_load_dim_vendor;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_vendor;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_vendor;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_vendor 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);

-- Verify location 2 history remains untouched in Gold
SELECT * FROM gold.dim_vendor WHERE vendor_id = 10;


-- 6. ADD SAME RECORD AGAIN TEST (Re-insertion / Re-activation Test)
INSERT INTO bronze.raw_vendor (vendor_id, vendor_name) 
VALUES (10, 'Abans1');

EXEC gold.sp_load_dim_vendor;

SELECT COUNT(*) AS bronze_cnt FROM bronze.raw_vendor;
SELECT COUNT(*) AS silver_cnt FROM silver.dim_vendor;
SELECT COUNT(*) AS gold_cnt FROM gold.dim_vendor 
WHERE CAST(ingested_at AS DATE) = CAST(GETDATE() AS DATE);

-- Verify location 2 gets a new active version created
SELECT * FROM gold.dim_vendor WHERE vendor_id = 10;