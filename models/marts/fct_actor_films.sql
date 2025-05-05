{{
  config(
    materialized = 'incremental',
    unique_key = 'actor_id || film_id || year'
  )
}}

-- This model stores the flattened actor-film relationships
SELECT
  actor,
  actor_id,
  film,
  year,
  votes,
  rating,
  film_id
FROM {{ ref('stg_actor_films') }}
{% if is_incremental() %}
  WHERE year > (SELECT MAX(year) FROM {{ this }})
{% endif %}