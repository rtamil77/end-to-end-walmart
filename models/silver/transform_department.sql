{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        pre_hook=copy_into_department(),
        alias='department',
        schema='silver',
        transient=true
    )
}}
with transform_department as (
    SELECT 
        TRY_CAST(store AS NUMBER) AS store,
        TRY_CAST(dept AS NUMBER) AS dept,
        TRY_CAST(date1 AS DATE) AS date1,
        TRY_CAST(weekly_sales AS NUMBER(12,2)) AS weekly_sales,
        TRY_CAST(is_holiday AS BOOLEAN) AS is_holiday,
        current_timestamp() AS insert_dts,
        update_dts,
        source_file_name,
        source_file_row_number
    FROM {{source('walmart_source','department') }}

    {% if is_incremental() %}
    WHERE  update_dts >= (SELECT coalesce(MAX(update_dts),'1990-01-01'::timestamp_ntz)
                        FROM {{ this }})
    {% endif %}
)
select * from transform_department