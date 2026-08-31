SELECT * FROM walmart_sales.gold.walmart_fact; -- 421570

SELECT * FROM walmart_sales.gold.walmart_store_dim; -- 3331

SELECT * FROM walmart_sales.gold.walmart_date_dim; -- 143

SELECT f.store_id,
        d.date,
        d.isholiday,
        SUM(f.store_weekly_sales) AS store_weekly_sales
FROM walmart_sales.gold.walmart_fact f
INNER JOIN walmart_sales.gold.walmart_date_dim d
ON f.date_id = d.date_id
GROUP BY f.store_id,d.date,d.isholiday
ORDER BY f.store_id,d.date;

SELECT f.store_id,
        d.date,
        d.isholiday,
        f.temperature,
        s.store_size,
        s.store_type,
        f.cpi,
        f.fuel_price, --Measure
        f.store_weekly_sales --Measure
FROM walmart_sales.gold.walmart_fact f
INNER JOIN walmart_sales.gold.walmart_date_dim d
ON f.date_id = d.date_id
INNER JOIN walmart_sales.gold.walmart_store_dim s
ON f.store_id = s.store_id
AND f.dept_id = s.dept_id
ORDER BY f.store_id,d.date;
