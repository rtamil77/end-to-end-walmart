{% snapshot snap_walmart_fact %}
{{
    config(
    target_database='walmart_sales',
    target_schema='gold',
    alias='walmart_fact',
    unique_key="store_id||'|'||dept_id||'|'||date_id",
    strategy="check",
    check_cols=['store_size','store_weekly_sales','fuel_price','temperature','unemployment','cpi','markdown1','markdown2',
                'markdown3','markdown4','markdown5'],
    snapshot_meta_column_names={
        'dbt_valid_from':'vrsn_start_date',
        'dbt_valid_to':'vrsn_end_date',
        'dbt_updated_at':'update_date'
        }
                )
}}

WITH store_dept_sales AS (
    SELECT s.store_id AS store_id, 
            s.dept_id AS dept_id,
            s.store_size AS store_size, 
            d.weekly_sales AS store_weekly_sales,
            d.date1 
    FROM {{ref('walmart_store_dim')}} s--walmart_sales.gold.walmart_store_dim s
    INNER JOIN {{ref('transform_department')}} d--walmart_sales.silver.department d
    ON s.store_id = d.store
    AND s.dept_id = d.dept
    {% if is_incremental() %}
        where d.update_dts >= (SELECT coalesce(MAX(update_date),'1990-01-01'::TIMESTAMP_NTZ)
                                FROM {{ this }})
    {% endif %}
    ),
deduplicated_walmart_fact AS (
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
        f.markdown5,
        row_number() OVER (PARTITION BY s.store_id,s.dept_id,dt.date_id ORDER BY f.update_dts desc,
                                f.source_file_name desc, f.source_file_row_number desc ) rn
    FROM {{ref('transform_fact')}} f --walmart_sales.silver.fact f
    INNER JOIN store_dept_sales s
    ON f.store = s.store_id
    AND f.date1 = s.date1
    INNER JOIN {{ref('walmart_date_dim')}} dt --walmart_sales.gold.walmart_date_dim dt
    ON f.date1 = dt.date
    {% if is_incremental() %}
        where f.update_dts >= (SELECT coalesce(MAX(update_date),'1990-01-01'::TIMESTAMP_NTZ)
                                FROM {{ this }})
    {% endif %})
SELECT d.store_id, 
       d.dept_id,
       d.date_id,
       d.store_size, 
       d.store_weekly_sales, 
        d.fuel_price,
        d.temperature,
        d.unemployment,
        d.cpi,
        d.markdown1,
        d.markdown2,
        d.markdown3,
        d.markdown4,
        d.markdown5
FROM deduplicated_walmart_fact d
WHERE d.rn = 1

{% endsnapshot %}