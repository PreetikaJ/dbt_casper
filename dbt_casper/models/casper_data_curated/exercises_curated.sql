{{ config(
    materialized='table'
  ) 
}}

with exercises_curated as (
  select
    ID as exercise_id,
    EXTERNAL_ID as patient_id,
    cast(MINUTES as float64) as exercise_minutes,
    cast(COMPLETED_AT as timestamp) as exercise_completed_at,
    cast(UPDATED_AT as timestamp) as exercise_updated_at
  from {{ source('casper_data_raw', 'exercises') }}
),

deduplicated as (
  select
    *,
    row_number() over (
        partition by exercise_id
        order by exercise_updated_at desc
    ) as row_num
  from exercises_curated
)

select 
  exercise_id,
  patient_id,
  exercise_minutes,
  exercise_completed_at,
  exercise_updated_at
from deduplicated
where row_num = 1