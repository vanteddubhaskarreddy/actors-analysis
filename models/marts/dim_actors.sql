{{
  config(
    materialized = 'incremental',
    unique_key = 'actor_id || current_year'
  )
}}

/*
  This model implements the cumulative actor table logic.
  For each new year, it combines:
  - New actor data from that year
  - Existing actor data from the previous year
  
  The logic is similar to your original Trino query but adapted for dbt.
*/

{% set this_year = var('current_processing_year', '2020') %} -- Default to 2020 if not provided
{% set last_year = this_year|int - 1 %}

WITH last_year_data AS (
  {% if is_incremental() %}
    -- Use existing data in this table for last year when running incrementally
    SELECT * 
    FROM {{ this }}
    WHERE current_year = {{ last_year }}
  {% else %}
    -- For initial run or full refresh, get data from source
    SELECT * 
    FROM {{ ref('stg_actors') }}
    WHERE current_year = {{ last_year }}
  {% endif %}
),

this_year_data AS (
  -- Get the aggregated actor-film data for the current year
  SELECT * 
  FROM {{ ref('int_actor_films_by_year') }}
  WHERE current_year = {{ this_year }}
)

-- Combine this year's actors with last year's data
SELECT
  COALESCE(ly.actor, ty.actor) AS actor,
  COALESCE(ly.actor_id, ty.actor_id) AS actor_id,
  ty.films, -- Films are only from current year's activity
  COALESCE(ty.quality_class, ly.quality_class) AS quality_class,
  ty.is_active IS NOT NULL AS is_active, -- is_active determined by current year's presence
  COALESCE(ty.current_year, ly.current_year + 1) AS current_year
FROM this_year_data AS ty
FULL OUTER JOIN last_year_data AS ly
  ON ty.actor_id = ly.actor_id AND ty.current_year = ly.current_year + 1