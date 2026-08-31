{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        pre_hook=copy_into_fact(),
        alias='fact',
        schema='silver',
        transient=true
    )
}}
with transform_fact as (
    select 
        store,
        date1,
        temperature,	
        fuel_price,	
        TRY_CAST(NULLIF(UPPER(TRIM(markdown1)),'NA') AS NUMBER(12,2)) AS markdown1,
        TRY_CAST(NULLIF(UPPER(TRIM(markdown2)),'NA') AS NUMBER(12,2)) AS markdown2,
        TRY_CAST(NULLIF(UPPER(TRIM(markdown3)),'NA') AS NUMBER(12,2)) AS markdown3,
        TRY_CAST(NULLIF(UPPER(TRIM(markdown4)),'NA') AS NUMBER(12,2)) AS markdown4,
        TRY_CAST(NULLIF(UPPER(TRIM(markdown5)),'NA') AS NUMBER(12,2)) AS markdown5,
        TRY_CAST(NULLIF(UPPER(TRIM(cpi)),'NA') AS NUMBER(16,7)) AS cpi,
        TRY_CAST(NULLIF(UPPER(TRIM(unemployment)),'NA') AS NUMBER(10,3)) AS unemployment,
        isHoliday,
        insert_dts,
        update_dts,
        source_file_name,
        source_file_row_number
    from {{source('walmart_source','fact') }}

    {% if is_incremental() %}
    WHERE  update_dts >= (SELECT coalesce(MAX(update_dts),'1990-01-01'::timestamp_ntz)
                        FROM {{ this }})
    {% endif %}
)
select * from transform_fact