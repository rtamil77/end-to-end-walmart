{{
    config(
        {"materialized":'incremental',
        "incremental_strategy":'merge',
        "merge_exclude_columns":['insert_date'],
        "unique_key": ['date_id'],
        "schema":'gold',
        "alias":'walmart_date_dim',
        "transient":false
        }
    )
}}
WITH walmart_date_dim AS (
SELECT DISTINCT
    TO_CHAR(date1,'YYYYMMDD') AS date_id,
    date1 AS date,
    is_holiday AS isholiday,
    CURRENT_TIMESTAMP() AS insert_date,
    update_dts AS update_date
FROM {{ref('transform_department')}}
    {% if is_incremental() %}
        where update_dts >= (SELECT coalesce(MAX(update_date),'1990-01-01'::TIMESTAMP_NTZ)
                                FROM {{ this }})
    {% endif %}
ORDER BY TO_CHAR(date1,'YYYYMMDD') --143 rows
)
SELECT * FROM walmart_date_dim