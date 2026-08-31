{% macro copy_into_fact() %}

{% set ingest_date = run_started_at.strftime('%Y-%m-%d') %}
{% set sql %}
COPY INTO walmart_sales.bronze.fact
FROM
(
SELECT  t.$1::NUMBER AS store,
        t.$2::DATE AS date1,
        t.$3::NUMBER AS temperature,	
        t.$4::NUMBER AS fuel_price,	
        t.$5::VARCHAR AS markdown1,
        t.$6::VARCHAR AS markdown2,
        t.$7::VARCHAR AS markdown3,
        t.$8::VARCHAR AS markdown4,
        t.$9::VARCHAR AS markdown5,
        t.$10::VARCHAR AS cpi,	
        t.$11::VARCHAR AS unemployment,	
        t.$12::BOOLEAN AS isHoliday,
        CURRENT_TIMESTAMP() AS insert_dts,
        CURRENT_TIMESTAMP() AS update_dts,
        metadata$filename AS source_file_name,
        metadata$file_row_number AS source_file_row_number
FROM @walmart_sales.bronze.my_s3_stage
    (PATTERN => '.*ingest_date={{ ingest_date }}/.*fact.csv$',
    FILE_FORMAT => walmart_sales.bronze.MY_CSV_FORMAT) AS t
)
FORCE = TRUE;
{% endset %}

{% if execute %}
    {% set result = run_query(sql) %}
{% endif%}

{% endmacro %}