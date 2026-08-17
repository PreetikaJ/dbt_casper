{{ config(
    materialized = 'incremental',
    unique_key = 'patient_id',
    incremental_strategy = 'merge', 
    cluster_by = ["country"]
) }}

with changed_patients as (
    {% if is_incremental() %}

    -- Patients with recent activity in steps or exercises
    select distinct patient_id
    from {{ source('casper_data_curated', 'sample_steps_incremental') }}
    where date(updated_at) >= date_add(
        (select max(date(load_datetime)) from {{ this }}),
        interval -1 day
    )

    union all

    select distinct patient_id
    from {{ source('casper_data_curated', 'sample_exercise_incremental') }}
    where date(exercise_updated_at) >= date_add(
        (select max(date(load_datetime)) from {{ this }}),
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
        sum(step_count * 0.002) as minutes_from_steps
    from {{ source('casper_data_curated', 'sample_steps_incremental') }}
    where patient_id in (select patient_id from changed_patients)
    group by patient_id

),

exercise_by_patient as (

    select
        patient_id,
        sum(exercise_minutes) as minutes_from_exercise
    from {{ source('casper_data_curated', 'sample_exercise_incremental') }}
    where patient_id in (select patient_id from changed_patients)
    group by patient_id

),

patients as (
    select
        patient_id,
        first_name,
        last_name,
        country
    from {{ source('casper_data_curated', 'sample_patients_incremental') }}
    where patient_id in (select patient_id from changed_patients)
),

patient_activity as (
    select
        p.patient_id,
        p.first_name,
        p.last_name,
        p.country,
        coalesce(s.minutes_from_steps, 0)
        + coalesce(e.minutes_from_exercise, 0) as total_minutes
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
    current_timestamp() as load_datetime
from patient_activity