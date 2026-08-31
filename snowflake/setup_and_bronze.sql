CREATE OR REPLACE STORAGE INTEGRATION etl_aws_walmart
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = 'S3'
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::919010206785:role/snowflake-s3-role'
STORAGE_ALLOWED_LOCATIONS = ('s3://walmart-project-rtamil/source/');


DESC INTEGRATION etl_aws_walmart


CREATE DATABASE walmart_sales;

CREATE SCHEMA walmart_sales.bronze;

USE walmart_sales.bronze;

CREATE OR REPLACE FILE FORMAT MY_CSV_FORMAT
TYPE = CSV
FIELD_DELIMITER = ','
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
SKIP_HEADER = 1
NULL_IF = ('NULL', 'null')
EMPTY_FIELD_AS_NULL = true;

CREATE STAGE my_s3_stage
STORAGE_INTEGRATION = etl_aws_walmart
URL = 's3://walmart-project-rtamil/source/'
FILE_FORMAT = MY_CSV_FORMAT;

LS @walmart_sales.bronze.my_s3_stage;
--s3://walmart-project-rtamil/source/ingest_date=2026-08-25/
SELECT  t.$1 AS store,
        t.$2 AS dept,
        t.$3 AS date1,
        t.$4 AS weekly_sales,
        t.$5 AS is_holiday,
        CURRENT_TIMESTAMP() AS insert_dts,
        CURRENT_TIMESTAMP() AS update_dts,
        metadata$filename AS source_file_name,
        metadata$file_row_number AS source_file_row_number
FROM @walmart_sales.bronze.my_s3_stage
    (PATTERN => '.*ingest_date=2026-08-26/.*department.csv$',
    FILE_FORMAT => walmart_sales.bronze.MY_CSV_FORMAT) AS t;

SELECT  t.*
FROM @walmart_sales.bronze.my_s3_stage
    (PATTERN => '.*department.csv$',
    FILE_FORMAT => walmart_sales.bronze.MY_CSV_FORMAT) AS t;

SELECT TO_CHAR(CURRENT_DATE(),'YYYY-MM-DD');

CREATE TABLE walmart_sales.bronze.department
(store VARCHAR,
dept VARCHAR,
date1 VARCHAR,
weekly_sales VARCHAR,
is_holiday VARCHAR,
insert_dts TIMESTAMP_LTZ,
update_dts TIMESTAMP_LTZ,
source_file_name VARCHAR,
source_file_row_number NUMBER
);

CREATE OR REPLACE TABLE walmart_sales.bronze.fact
(
store	NUMBER,
date1	TIMESTAMP_LTZ,
temperature	NUMBER(12,5),	
fuel_price	NUMBER(12,5),	
markdown1	VARCHAR,
markdown2	VARCHAR,
markdown3	VARCHAR,
markdown4	VARCHAR,
markdown5	VARCHAR,
cpi	    VARCHAR,	
unemployment  VARCHAR,	
isHoliday   BOOLEAN,
insert_dts TIMESTAMP_LTZ,
update_dts TIMESTAMP_LTZ,
source_file_name VARCHAR,
source_file_row_number NUMBER
);

CREATE OR REPLACE TABLE walmart_sales.bronze.stores
(store	NUMBER,
type1	varchar,
size1	NUMBER(12,5),
insert_dts TIMESTAMP_LTZ,
update_dts TIMESTAMP_LTZ,
source_file_name VARCHAR,
source_file_row_number NUMBER
);




COPY INTO walmart_sales.bronze.department
FROM
(
SELECT  t.$1 AS store,
        t.$2 AS dept,
        t.$3 AS date1,
        t.$4 AS weekly_sales,
        t.$5 AS is_holiday,
        CURRENT_TIMESTAMP() AS insert_dts,
        CURRENT_TIMESTAMP() AS update_dts,
        metadata$filename AS source_file_name,
        metadata$file_row_number AS source_file_row_number
FROM @walmart_sales.bronze.my_s3_stage
    (PATTERN => '.*ingest_date=2026-08-26/.*department.csv$',
    FILE_FORMAT => walmart_sales.bronze.MY_CSV_FORMAT) AS t
)
FORCE = TRUE;

truncate table walmart_sales.bronze.stores;

SELECT * FROM walmart_sales.bronze.fact; -- 8190

select * from walmart_sales.bronze.department; -- 421750

select * from walmart_sales.bronze.stores; -- 45


CREATE SCHEMA walmart_sales.silver;

USE walmart_sales.silver;
