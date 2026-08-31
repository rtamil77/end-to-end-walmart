{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        pre_hook=copy_into_stores(),
        alias='stores',
        schema='silver',
        transient=true
    )
}}
with transform_stores as (
    select store,
        type1,
        size1,
        insert_dts,
        update_dts,
        source_file_name,
        source_file_row_number
    from {{source('walmart_source','stores') }}

    {% if is_incremental() %}
    WHERE  update_dts >= (SELECT coalesce(MAX(update_dts),'1990-01-01'::timestamp_ntz)
                        FROM {{ this }})
    {% endif %}
)
select * from transform_stores