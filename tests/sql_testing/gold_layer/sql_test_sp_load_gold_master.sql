/*******************************************************************************
 * NYC TAXI PIPELINE: SCD TYPE 1 TESTING SUITE (dim_payment / dim_rate_code)
 *******************************************************************************/

-- 1. INITIAL LOAD TEST (Fresh Load / Truncate and Insert)
EXEC gold.sp_load_gold_master;

SELECT COUNT(*) AS initial_row_count FROM gold.dim_payment;
SELECT * FROM gold.dim_payment;


-- 2. RERUN LOAD TEST (Idempotency Check)
-- Running this a second time should not duplicate rows or cause errors
EXEC gold.sp_load_gold_master;

SELECT COUNT(*) AS rerun_row_count FROM gold.dim_payment;


-- 3. CHANGE DATA RECORD TEST (SCD Type 1 Overwrite Test)
-- Modify a payment description in the source/silver layer
UPDATE silver.dim_payment 
SET payment_type_desc = 'Cash (Updated)' 
WHERE payment_type_id = 2;

-- Execute the SCD Type 1 load (which truncates and reloads, or updates in place)
EXEC gold.sp_load_gold_master;

-- Verify that payment_id 2 now shows the updated description with NO old history row
SELECT COUNT(*) AS new_count FROM gold.dim_payment;
SELECT * FROM gold.dim_payment WHERE payment_type_id = 2;


-- 4. ADDING NEW RECORD TEST
-- Insert a brand-new payment type into the source/silver layer
INSERT INTO silver.dim_payment (payment_type_id, payment_type_desc) 
VALUES (8, 'Contactless');

EXEC gold.sp_load_gold_master;

-- Verify the new record appears correctly
SELECT COUNT(*) AS new_count FROM gold.dim_payment;
SELECT * FROM gold.dim_payment WHERE payment_type_id = 8;


-- 5. REMOVING ONE RECORD TEST (Source Deletion Handling)
-- Delete payment_type_id 8 from the source/silver layer
DELETE FROM silver.dim_payment 
WHERE payment_type_id = 8 ;

EXEC gold.sp_load_gold_master;

-- Verify behavior: If using a full truncate/reload pattern, id 6 will disappear from Gold.
SELECT * FROM gold.dim_payment WHERE payment_type_id = 8;