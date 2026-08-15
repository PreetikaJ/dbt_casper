{{ config(
    materialized='table'
  ) 
}}

with exercises_curated as (
  select
    ID as exercise_id,
    EXTERNAL_ID as patients_id,
    cast(MINUTES as float64) as exercise_minutes,
    cast(COMPLETED_AT as timestamp) as exercise_completed_at,
    cast(UPDATED_AT as timestamp) as exercise_updated_at
  from {{ source('casper_data_raw', 'exercises') }}
)

select distinct *
from exercises_curated