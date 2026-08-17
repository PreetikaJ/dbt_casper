{{ config(
    materialized='table'
  ) 
}}

with patients_curated as (
  select
    PATIENT_ID as patient_id,
    trim(first_name) as first_name,
    trim(last_name) as last_name,
    trim(country) as country
  from {{ source('casper_data_raw', 'patients') }}
),

deduplicated as (
  select
    *,
    row_number() over (
        partition by patient_id
        order by patient_id
    ) as row_num
  from patients_curated
)

select 
    patient_id,
    first_name,
    last_name,
    country
from deduplicated
where row_num = 1