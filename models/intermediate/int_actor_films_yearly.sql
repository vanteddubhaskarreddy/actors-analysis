{{
  config(
    materialized = 'incremental',
    unique_key = 'actor_id || year'
  )
}}

-- Aggregates film data by actor and year
SELECT
  actor,
  actor_id,
  year,
  ARRAY_AGG(
    ROW(
      film,
      votes,
      rating,
      film_id
    )
  ) AS films,
  -- Calculate actor quality class based on average rating
  CASE
    WHEN AVG(rating) > 8 THEN 'star'
    WHEN AVG(rating) > 7 AND AVG(rating) <= 8 THEN 'good'
    WHEN AVG(rating) > 6 AND AVG(rating) <= 7 THEN 'average'
    WHEN AVG(rating) <= 6 THEN 'bad'
  END AS quality_class,
  -- Actor is active if they have at least one film this year
  COUNT(film_id) > 0 AS is_active,
  year AS current_year
FROM {{ ref('stg_actor_films') }}
{% if is_incremental() %}
  -- Only process new years of data when running incrementally
  WHERE year > (SELECT MAX(current_year) FROM {{ this }})
{% endif %}
GROUP BY actor, actor_id, year