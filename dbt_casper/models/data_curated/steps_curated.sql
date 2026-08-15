{{ config(
    materialized='table'
  ) 
}}

with steps_curated as (
  select
    ID as steps_id,
    EXTERNAL_ID as patients_id,
    STEPS as step_count,
    cast(SUBMISSION_TIME as timestamp) as submission_time,
    cast(UPDATED_AT as timestamp) as updated_at
  from {{ source('casper_data_raw', 'steps') }}
)

select distinct *
from steps_curated