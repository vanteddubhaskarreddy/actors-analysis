{{
  config(
    materialized = 'view'
  )
}}

-- Simple staging model to prepare current actor data
SELECT
  actor,
  actor_id,
  films,
  quality_class,
  is_active,
  current_year
FROM {{ source('bhaskar_reddy07', 'actors') }}