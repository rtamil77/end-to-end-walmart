SELECT * FROM walmart_sales.bronze.fact; -- 8190

select * from walmart_sales.bronze.department; -- 421750

select * from walmart_sales.bronze.stores; -- 45

SELECT  store, -- number
        type1, -- 
        size1 -- number
from walmart_sales.bronze.stores
where store is null
or type1 is null
or size1 is null;

with transform_stores as (
    select store,
        type1,
        size1,
        insert_dts,
        update_dts,
        source_file_name,
        source_file_row_number
    from walmart_sales.bronze.stores
)
select * from transform_stores

SELECT 
    store,
    date1,
    temperature,	
    fuel_price,	
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    cpi,	
    unemployment,	
    isHoliday,
    insert_dts,
    update_dts,
    source_file_name,
    source_file_row_number
FROM walmart_sales.bronze.fact;

select case when trim(markdown1) = 'NA'
            then null
            else --trim(markdown1)::number(12,2) -- 
            --cast(trim(markdown1) as number(12,2))
            
            end as markdown1
FROM walmart_sales.bronze.fact;

SELECT 
    store,
    date1,
    temperature,	
    fuel_price,	
    TRY_CAST(NULLIF(UPPER(TRIM(markdown1)),'NA') AS NUMBER(12,2)) AS markdown1,
    TRY_CAST(NULLIF(UPPER(TRIM(markdown2)),'NA') AS NUMBER(12,2)) AS markdown2,
    TRY_CAST(NULLIF(UPPER(TRIM(markdown3)),'NA') AS NUMBER(12,2)) AS markdown3,
    TRY_CAST(NULLIF(UPPER(TRIM(markdown4)),'NA') AS NUMBER(12,2)) AS markdown4,
    TRY_CAST(NULLIF(UPPER(TRIM(markdown5)),'NA') AS NUMBER(12,2)) AS markdown5,
    TRY_CAST(NULLIF(UPPER(TRIM(markdown5)),'NA') AS NUMBER(12,2)) AS markdown5,
    TRY_CAST(NULLIF(UPPER(TRIM(cpi)),'NA') AS NUMBER(16,7)) AS cpi,
    TRY_CAST(NULLIF(UPPER(TRIM(unemployment)),'NA') AS NUMBER(10,3)) AS unemployment,
    isHoliday,
    insert_dts,
    update_dts,
    source_file_name,
    source_file_row_number
FROM walmart_sales.bronze.fact;

SELECT * FROM walmart_sales.silver.fact;

SELECT 
    TRY_CAST(store AS NUMBER) AS store,
    TRY_CAST(dept AS NUMBER) AS dept,
    TRY_CAST(date1 AS DATE) AS date1,
    TRY_CAST(weekly_sales AS NUMBER(12,2)) AS weekly_sales,
    TRY_CAST(is_holiday AS BOOLEAN) AS is_holiday,
    insert_dts,
    update_dts,
    source_file_name,
    source_file_row_number
FROM walmart_sales.bronze.department;

CREATE schema gold;

USE walmart_sales.gold;

'''store VARCHAR,
dept VARCHAR,
date1 VARCHAR,
weekly_sales VARCHAR,
is_holiday VARCHAR,'''

SELECT * FROM walmart_sales.silver.department;


CREATE OR REPLACE TABLE walmart_sales.gold.walmart_date_dim
(date_id NUMBER PRIMARY KEY,
date DATE,
isholiday BOOLEAN,
insert_date DATE,
update_date DATE);

CREATE OR REPLACE TABLE walmart_sales.gold.walmart_store_dim
(store_id NUMBER,
dept_id NUMBER,
store_type varchar,
store_size NUMBER,
insert_date DATE,
update_date DATE,
PRIMARY KEY (store_id,dept_id));

CREATE OR REPLACE TABLE walmart_sales.gold.walmart_fact_table
(store_id NUMBER,
dept_id NUMBER,
date_id NUMBER,
store_size NUMBER,
store_weekly_sales NUMBER,
fuel_price NUMBER,
temperature NUMBER,
unemployment NUMBER,
cpi NUMBER,
markdown1 NUMBER,
markdown2 NUMBER,
markdown3 NUMBER,
markdown4 NUMBER,
markdown5 NUMBER,
vrsn_start_date DATE,
vrsn_end_date DATE,
insert_date DATE,
update_date DATE,
FOREIGN KEY (store_id,dept_id) REFERENCES walmart_sales.gold.walmart_store_dim (store_id,dept_id),
FOREIGN KEY (date_id) REFERENCES walmart_sales.gold.walmart_date_dim (date_id)
);WALMART_SALES.GOLD.SNAP_WALMART_FACT

DROP TABLE walmart_sales.gold.walmart_fact_table;

truncate table walmart_sales.bronze.stores;

truncate table walmart_sales.bronze.department;

truncate table walmart_sales.bronze.fact;

truncate table walmart_sales.silver.stores;

truncate table walmart_sales.silver.department;

truncate table walmart_sales.silver.fact;

truncate table walmart_sales.gold.walmart_fact;

truncate table walmart_sales.gold.walmart_store_dim;

truncate table walmart_sales.gold.walmart_date_dim;

SELECT * FROM walmart_sales.silver.fact; -- 8190

SELECT * FROM walmart_sales.silver.department; -- 421750

SELECT * FROM walmart_sales.silver.stores; -- 45

SELECT * FROM walmart_sales.gold.walmart_fact; -- 421570

SELECT * FROM walmart_sales.gold.walmart_store_dim; -- 3331

SELECT * FROM walmart_sales.gold.walmart_date_dim; -- 143


walmart_sales.gold.walmart_store_dim
(store_id NUMBER, -- store FROM stores
dept_id NUMBER, -- dept from department
store_type varchar, -- type1 FROM stores
store_size NUMBER, -- size1 FROM stores
insert_date DATE, --CURRENT_TIMESTAMP()
update_date DATE, --CURRENT_TIMESTAMP()

WITH walmart_store_dim AS (
    SELECT DISTINCT 
            d.store AS store_id,
            d.dept AS dept_id,
            s.type1 AS store_type,
            s.size1 AS store_size,
            CURRENT_TIMESTAMP() AS insert_date,
            CURRENT_TIMESTAMP() AS update_date
    FROM walmart_sales.silver.department d
    JOIN walmart_sales.silver.stores s
    ON d.store = s.store
    ORDER BY d.store,d.dept 
)
SELECT *
FROM walmart_store_dim; --3331 rows

walmart_sales.gold.walmart_date_dim
date_id NUMBER PRIMARY KEY, -- TO_CHAR(CURRENT_DATE(),'YYYYMMDD')
date DATE, -- date1 from department
isholiday BOOLEAN,  -- isholiday from department
insert_date DATE, -- CURRENT_TIMESTAMP()
update_date DATE  --CURRENT_TIMESTAMP()


WITH walmart_date_dim AS (
SELECT DISTINCT
    TO_CHAR(date1,'YYYYMMDD') AS date_id,
    date1 AS date,
    is_holiday AS isholiday,
    CURRENT_TIMESTAMP() AS insert_date,
    CURRENT_TIMESTAMP() AS update_date
FROM walmart_sales.silver.department
ORDER BY TO_CHAR(date1,'YYYYMMDD') --143 rows
)
SELECT * FROM walmart_date_dim

SELECT * FROM walmart_sales.gold.walmart_date_dim;

SELECT
    s.store_id AS store_id, 
    s.dept_id AS dept_id,
    dt.date_id AS date_id,
    s.store_size AS store_size, 
    d.weekly_sales AS store_weekly_sales, -- silver.department,
    f.fuel_price,
    f.temperature,
    f.unemployment,
    f.cpi,
    f.markdown1,
    f.markdown2,
    f.markdown3,
    f.markdown4,
    f.markdown5
FROM walmart_sales.silver.fact f
INNER JOIN walmart_sales.gold.walmart_store_dim s
ON f.store = s.store_id
INNER JOIN walmart_sales.gold.walmart_date_dim dt
ON f.date1 = dt.date
INNER JOIN walmart_sales.silver.department d
ON s.store_id = d.store
AND s.dept_id = d.dept

SELECT * 
FROM walmart_sales.silver.department;

DESC walmart_sales.silver.department; 

WITH store_dept_sales AS (
    SELECT s.store_id AS store_id, 
            s.dept_id AS dept_id,
            s.store_size AS store_size, 
            d.weekly_sales AS store_weekly_sales,
            d.date1 
    FROM walmart_sales.gold.walmart_store_dim s
    INNER JOIN walmart_sales.silver.department d
    ON s.store_id = d.store
    AND s.dept_id = d.dept),
walmart_fact AS (
    SELECT
        s.store_id AS store_id, 
        s.dept_id AS dept_id,
        dt.date_id AS date_id,
        s.store_size AS store_size, 
        s.store_weekly_sales, 
        f.fuel_price,
        f.temperature,
        f.unemployment,
        f.cpi,
        f.markdown1,
        f.markdown2,
        f.markdown3,
        f.markdown4,
        f.markdown5
    FROM walmart_sales.silver.fact f
    INNER JOIN store_dept_sales s
    ON f.store = s.store_id
    AND f.date1 = s.date1
    INNER JOIN walmart_sales.gold.walmart_date_dim dt
    ON f.date1 = dt.date)
SELECT *
FROM walmart_fact

select *
from walmart_fact




