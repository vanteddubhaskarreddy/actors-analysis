{{
  config(
    materialized = 'view'
  )
}}

-- Simple staging model to prepare actor history data
SELECT
  actor,
  actor_id,
  quality_class,
  is_active,
  start_date,
  end_date,
  current_year
FROM {{ source('bhaskar_reddy07', 'actors_history_scd') }}