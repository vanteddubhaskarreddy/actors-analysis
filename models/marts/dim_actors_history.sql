{{
  config(
    materialized = 'incremental',
    unique_key = 'actor_id || start_date'
  )
}}

/*
  This model implements the SCD Type 2 history for actor attributes.
  It has two operation modes:
  1. Full backfill (initial load): Uses the backfill logic to build full history
  2. Incremental: Uses year-by-year logic to append new history records
*/

{% set this_year = var('current_processing_year', '2020') %} -- Default to 2020 if not provided
{% set last_year = this_year|int - 1 %}

{% if not is_incremental() %}
-- BACKFILL MODE: Initial load logic to build complete historical SCD
WITH actor_history AS (
  SELECT
    actor,
    actor_id,
    quality_class,
    LAG(quality_class, 1) OVER(PARTITION BY actor_id ORDER BY current_year) AS quality_class_prev,
    is_active,
    LAG(is_active, 1) OVER(PARTITION BY actor_id ORDER BY current_year) AS is_active_prev,
    current_year
  FROM {{ ref('dim_actors') }}
),

streak_identification AS (
  SELECT
    *,
    SUM(
      CASE
        WHEN is_active <> is_active_prev OR quality_class <> quality_class_prev
          OR is_active_prev IS NULL OR quality_class_prev IS NULL
          THEN 1
        ELSE 0
      END
    ) OVER(PARTITION BY actor_id ORDER BY current_year) AS streak_id
  FROM actor_history
)

-- Create SCD records by grouping streaks
SELECT
  actor,
  actor_id,
  MAX(quality_class) AS quality_class,
  MAX(is_active) AS is_active,
  CAST(CAST(MIN(current_year) AS VARCHAR) || '-01-01' AS DATE) AS start_date,
  CAST(CAST(MAX(current_year) AS VARCHAR) || '-12-31' AS DATE) AS end_date,
  {{ this_year }} AS current_year  -- Processing year
FROM streak_identification
GROUP BY actor, actor_id, streak_id

{% else %}
-- INCREMENTAL MODE: Year-by-year update logic
WITH last_year_scd AS (
  -- Get last year's SCD records
  SELECT *
  FROM {{ this }}
  WHERE current_year = {{ last_year }}
),

this_year_actors AS (
  -- Get this year's actor data
  SELECT *
  FROM {{ ref('dim_actors') }}
  WHERE current_year = {{ this_year }}
),

joined_data AS (
  -- Join previous year's SCD with this year's actor data
  SELECT
    COALESCE(ly.actor, ty.actor) AS actor,
    COALESCE(ly.actor_id, ty.actor_id) AS actor_id,
    COALESCE(ly.start_date, CAST(CAST(ty.current_year AS VARCHAR) || '-01-01' AS DATE)) AS start_date,
    COALESCE(ly.end_date, CAST(CAST(ty.current_year AS VARCHAR) || '-12-31' AS DATE)) AS end_date,
    ly.is_active AS is_active_last_year,
    ty.is_active AS is_active_this_year,
    ly.quality_class AS quality_class_last_year,
    ty.quality_class AS quality_class_this_year,
    (ly.is_active <> ty.is_active OR ly.quality_class <> ty.quality_class) AS did_change,
    {{ this_year }} AS current_year
  FROM last_year_scd ly
  FULL OUTER JOIN this_year_actors ty
    ON ly.actor_id = ty.actor_id
  WHERE COALESCE(EXTRACT(YEAR FROM ly.end_date), ty.current_year - 1) = ty.current_year - 1
),

computed_changes AS (
  -- Create records based on detected changes
  SELECT
    actor,
    actor_id,
    CASE
      WHEN did_change = FALSE THEN
        quality_class_last_year
      ELSE
        quality_class_this_year
    END AS quality_class,
    CASE
      WHEN did_change = FALSE THEN
        is_active_last_year
      ELSE
        is_active_this_year
    END AS is_active,
    CASE
      WHEN did_change = FALSE THEN
        start_date
      ELSE
        CAST(CAST(current_year AS VARCHAR) || '-01-01' AS DATE)
    END AS start_date,
    CASE
      WHEN did_change = FALSE THEN
        end_date + INTERVAL '1' YEAR
      ELSE
        CAST(CAST(current_year AS VARCHAR) || '-12-31' AS DATE)
    END AS end_date,
    current_year
  FROM joined_data
)

-- Return the final updated SCD records
SELECT
  actor,
  actor_id,
  quality_class,
  is_active,
  start_date,
  end_date,
  current_year
FROM computed_changes
{% endif %}