{% macro copy_into_department() %}

{% set ingest_date = run_started_at.strftime('%Y-%m-%d') %}
{% set sql %}
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
    (PATTERN => '.*ingest_date={{ ingest_date }}/.*department.csv$',
    FILE_FORMAT => walmart_sales.bronze.MY_CSV_FORMAT) AS t
)
FORCE = TRUE;
{% endset %}

{% if execute %}
    {% set result = run_query(sql) %}
{% endif%}

{% endmacro %}