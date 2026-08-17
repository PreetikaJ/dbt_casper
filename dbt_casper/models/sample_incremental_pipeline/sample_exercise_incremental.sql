{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "exercise_updated_at",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=["patient_id"]
) }}

with source_data as (
    select
        exercise_id,
        patient_id,
        exercise_minutes,
        exercise_completed_at,
        exercise_updated_at
    from {{ source('casper_data_raw', 'sample_exercises') }}

    {% if is_incremental() %}
        where exercise_updated_at >= (
            select date_add(max(exercise_updated_at), interval -1 day)
            from {{ this }}
        )
    {% endif %}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by exercise_id
            order by exercise_updated_at desc
        ) as row_num
    from source_data
)

select
    exercise_id,
    patient_id,
    exercise_minutes,
    exercise_completed_at,
    exercise_updated_at,
    current_timestamp() as load_datetime
from deduplicated
where row_num = 1
