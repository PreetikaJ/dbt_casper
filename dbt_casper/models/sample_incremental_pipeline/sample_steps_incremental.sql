{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "updated_at",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["patient_id"]
) }}

with source_data as (
    select
        steps_id,
        patient_id,
        step_count,
        submission_time,
        updated_at
    from {{ source('casper_data_raw', 'sample_steps') }}
    {% if is_incremental() %}
        where updated_at >= (
            select date_add(max(updated_at), interval -1 day)
            from {{ this }}
        )
    {% endif %}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by steps_id
            order by updated_at desc
        ) as row_num
    from source_data
)

select
    steps_id,
    patient_id,
    step_count,
    submission_time,
    updated_at,
    current_timestamp() as load_datetime
from deduplicated
where row_num = 1
