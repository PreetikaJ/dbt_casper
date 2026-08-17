{{ config(
    materialized = 'incremental',
    unique_key = 'patient_id',
    incremental_strategy = 'merge',
    cluster_by = ["country"]
) }}

with changed_patients as (
    {% if is_incremental() %}

    -- Patients with recent activity in steps or exercises
    select patient_id
    from {{ source('casper_data_curated', 'sample_steps_incremental') }}
    where updated_at >= date_add(
            (select max(last_activity_updated_at) from {{ this }}),
        interval -1 day
    )

    union distinct

    select patient_id
    from {{ source('casper_data_curated', 'sample_exercise_incremental') }}
    where exercise_updated_at >= date_add(
            (select max(last_activity_updated_at) from {{ this }}),
        interval -1 day
    )

    {% else %}

    -- Full load: start from all patients
    select patient_id
    from {{ source('casper_data_curated', 'sample_patients_incremental') }}

    {% endif %}

),

steps_by_patient as (
    select
        patient_id,
        sum(step_count * 0.002) as minutes_from_steps,
        max(updated_at) as steps_last_updated
    from {{ source('casper_data_curated', 'sample_steps_incremental') }}
    {% if is_incremental() %}
    where patient_id in (select patient_id from changed_patients)
    {% endif %}
    group by patient_id
),

exercise_by_patient as (
    select
        patient_id,
        sum(exercise_minutes) as minutes_from_exercise,
        max(exercise_updated_at) as exercises_last_updated
    from {{ source('casper_data_curated', 'sample_exercise_incremental') }}
    {% if is_incremental() %}
    where patient_id in (select patient_id from changed_patients)
    {% endif %}
    group by patient_id
),

patients as (
    select
        patient_id,
        first_name,
        last_name,
        country
    from {{ source('casper_data_curated', 'sample_patients_incremental') }}
    -- No filter by changed_patients: we want all patients
),

patient_activity as (
    select
        p.patient_id,
        p.first_name,
        p.last_name,
        p.country,
        coalesce(s.minutes_from_steps, 0)
        + coalesce(e.minutes_from_exercise, 0) as total_minutes,
        greatest(
            coalesce(s.steps_last_updated, date('1900-01-01')), 
            coalesce(e.exercises_last_updated, date('1900-01-01'))
        ) as last_activity_updated_at
    from patients p
    left join steps_by_patient s
        on p.patient_id = s.patient_id
    left join exercise_by_patient e
        on p.patient_id = e.patient_id
)

select
    patient_id,
    first_name,
    last_name,
    country,
    cast(round(total_minutes) as int64) as total_minutes,
    last_activity_updated_at,
    current_timestamp() as load_datetime
from patient_activity