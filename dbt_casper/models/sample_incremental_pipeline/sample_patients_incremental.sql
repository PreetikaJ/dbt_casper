{{ config(
    materialized='incremental',
    unique_key='patient_id',
    incremental_strategy='merge',
    cluster_by=["country"]
) }}

with source_data as (
    select
        patient_id,
        first_name,
        last_name,
        country
    from {{ source('casper_data_raw', 'sample_patients') }}
    {% if is_incremental() %}
        where patient_id not in (
            select patient_id
            from {{ this }}
        )
    {% endif %}
),

deduplicated as (
  select
    *,
    row_number() over (
        partition by patient_id
        order by patient_id
    ) as row_num
  from source_data
)

select 
    patient_id,
    first_name,
    last_name,
    country,
    current_timestamp() as load_datetime
from deduplicated
where row_num = 1