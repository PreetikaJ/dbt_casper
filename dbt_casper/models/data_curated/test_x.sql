{{ config(
    materialized='table'
  ) 
}}

SELECT
    steps,
    TYPEOF(steps) AS steps_type
FROM {{ source('casper_data_raw', 'steps') }}
LIMIT 10