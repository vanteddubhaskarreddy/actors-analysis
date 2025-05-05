{{
  config(
    materialized = 'view'
  )
}}

-- Simple staging model to prepare actor film data from source
SELECT
  actor,
  actor_id,
  film,
  year,
  votes,
  rating,
  film_id
FROM {{ source('academy', 'actor_films') }}