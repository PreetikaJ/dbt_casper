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
)

select *
from patients_curated