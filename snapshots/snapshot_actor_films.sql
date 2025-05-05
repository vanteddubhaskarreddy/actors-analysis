{% snapshot snapshot_actors %}

{{
    config(
      target_database='dataexpert_student',
      target_schema=env_var('DBT_SCHEMA'),
      unique_key='actor_id',
      strategy='check',
      check_cols=['quality_class', 'is_active'],
    )
}}

select
    actor,
    actor_id,
    quality_class,
    is_active,
    current_year,
    current_timestamp() as dbt_updated_at
from {{ source('academy', 'actor_films') }}

{% endsnapshot %}