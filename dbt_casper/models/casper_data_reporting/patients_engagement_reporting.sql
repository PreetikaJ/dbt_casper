{{ config(
    materialized='table',
    cluster_by=['country']
) }}

with steps_by_patient as (
    select 
        patient_id,
        -- Business rule:
        -- 1 step = 0.002 generated minutes
        sum(step_count * 0.002) as minutes_from_steps
    from {{ source('casper_data_curated', 'steps_curated') }}
    group by patient_id
),

exercises_by_patient as (
    select 
        patient_id,
        -- Exercise minutes are already expressed in minutes
        sum(exercise_minutes) as minutes_from_exercise
    from {{ source('casper_data_curated', 'exercises_curated') }} 
    group by patient_id
),

patient_engagement as (
    select 
        p.patient_id,
        p.first_name,
        p.last_name,
        p.country,
        coalesce(s.minutes_from_steps, 0)
        + coalesce(e.minutes_from_exercise, 0)
            as total_minutes
    from {{ source('casper_data_curated', 'patients_curated') }} as p
    left join steps_by_patient as s
        on p.patient_id = s.patient_id
    left join exercises_by_patient as e
        on p.patient_id = e.patient_id
)

select 
    patient_id,
    first_name,
    last_name,
    country,
    cast(round(total_minutes) as int64) as total_minutes
from patient_engagement