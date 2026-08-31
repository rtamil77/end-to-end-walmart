{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        merge_exclude_columns=['insert_date'],
        unique_key= ['store_id','dept_id'],
        schema='gold',
        alias='walmart_store_dim',
        transient=false
    )
}}

WITH incremental_walmart_store_dim AS (
    SELECT DISTINCT 
            d.store AS store_id,
            d.dept AS dept_id,
            s.type1 AS store_type,
            s.size1 AS store_size,
            CURRENT_TIMESTAMP() AS insert_date,
            s.update_dts AS update_date,
            s.source_file_name,
            s.source_file_row_number
    FROM {{ref('transform_department')}} d
    INNER JOIN {{ref('transform_stores')}} s
    ON d.store = s.store

    {% if is_incremental() %}
        where s.update_dts >= (SELECT coalesce(MAX(update_date),'1990-01-01'::TIMESTAMP_NTZ)
                                FROM {{ this }})
    {% endif %}
    ORDER BY d.store,d.dept 
),
deduplicated AS (
    SELECT store_id,
           dept_id,
           store_type,
           store_size,
           insert_date,
           update_date,
           row_number() OVER (PARTITION BY store_id,dept_id ORDER BY update_date desc,
                                source_file_name desc, source_file_row_number desc ) rn
    FROM incremental_walmart_store_dim)
SELECT d.store_id,
           d.dept_id,
           d.store_type,
           d.store_size,
           coalesce(t.insert_date, current_timestamp()) AS insert_date,
           d.update_date
FROM deduplicated d
left join {{ this }} t
on d.store_id = t.store_id
and d.dept_id = t.dept_id 
WHERE d.rn = 1


/*,
deduplicated AS (
    SELECT *,
            qualify row_number() OVER (PARTITION BY store_id,dept_id ORDER BY update_date DESC) = 1
    FROM base_query
),
walmart_store_dim AS (
    WHERE NOT EXISTS (SELECT 1 FROM { this } as target
                        WHERE target.store = deduplicated.store
                        AND )
)
SELECT *
FROM walmart_store_dim*/