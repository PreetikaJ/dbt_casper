{{ config(
    materialized='table'
  ) 
}}

with patients_curated as (
  select
    PATIENT_ID as patient_id,
    first_name,
    last_name,
    country
  from {{ source('casper_data_raw', 'patients') }}
)

select distinct *
from patients_curated