{{ config(
    materialized='table'
  ) 
}}

with steps_curated as (
  select
    s.ID as steps_id,
    s.EXTERNAL_ID as patient_id,
    cast(s.STEPS as int64) as step_count,
    cast(s.SUBMISSION_TIME as timestamp) as submission_time,
    cast(s.UPDATED_AT as timestamp) as updated_at
  from {{ source('casper_data_raw', 'steps') }} as s
),

deduplicated as (
  select
    *,
    row_number() over (
        partition by steps_id
        order by updated_at desc
    ) as row_num
  from steps_curated
)

select
  steps_id,
  patient_id,
  step_count,
  submission_time,
  updated_at
from deduplicated
where row_num = 1