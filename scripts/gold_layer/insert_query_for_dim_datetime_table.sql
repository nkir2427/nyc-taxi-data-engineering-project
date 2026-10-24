
WITH HoursCTE AS (
    SELECT CAST('2017-01-01 00:00:00' AS DATETIME2) AS dt
    UNION ALL
    SELECT DATEADD(hour, 1, dt)
    FROM HoursCTE
    WHERE dt < CAST('2018-01-01 00:00:00' AS DATETIME2)
    --CAST(GETDATE() AS DATETIME2)
)
INSERT INTO gold.dim_datetime (datetime_id, full_datetime, date_key,month_id, year, month, day, hour, day_of_week, is_weekend)
SELECT 
    CAST(FORMAT(dt, 'yyyyMMddHH') AS INT) AS datetime_id,
    dt AS full_datetime,
    CAST(dt AS DATE) AS date_key,
    CAST(FORMAT(dt, 'yyyyMM') AS INT) AS month_id,
    YEAR(dt) AS year,
    MONTH(dt) AS month,
    DAY(dt) AS day,
    DATEPART(hour, dt) AS hour,
    DATENAME(dw, dt) AS day_of_week,
    CASE WHEN DATEPART(dw, dt) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
FROM HoursCTE
OPTION (MAXRECURSION 9000); -- Allows recursion for hours in a year (~8760 hours)
GO


select * from gold.dim_datetime

--delete from gold.dim_datetime;


