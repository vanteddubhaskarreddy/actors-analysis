# Actors Analysis - Data Engineering Project

![dbt](https://img.shields.io/badge/dbt-FF694B?style=for-the-badge&logo=dbt&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-025E8C?style=for-the-badge&logo=sql&logoColor=white)

A dbt project that demonstrates data engineering capabilities through actor performance analysis using incremental processing and slowly changing dimensions.

## Project Overview

This project ingests actor and film data from raw sources, models it using dbt, and builds a dimensional model for analyzing actor performances over time.

Key features:
- Incremental year-by-year processing
- Type 2 Slowly Changing Dimension implementation
- Nested data structures for film collections
- Quality classification of actors based on film ratings

## Data Model

![Data Model](https://fakeimg.pl/800x400/ff694b/fff9f8?text=Actor+Analysis+Data+Model)

### Sources
- **academy.actor_films**: Raw actor-film relationship data
- **bhaskar_reddy07.actors**: Actor information with nested film data
- **bhaskar_reddy07.actors_history_scd**: Historical SCD tracking

### Final Data Marts
- **dim_actors**: Current actor dimensions with quality classifications
- **dim_actors_history_scd**: Historical tracking of actor attribute changes
- **fct_actor_films**: Film facts with ratings and votes

## Technical Implementation

### Incremental Processing

This project implements a sophisticated year-by-year processing approach where:

1. Actor data is aggregated annually
2. Quality classifications are calculated based on average film ratings:
   - **star**: Average rating > 8
   - **good**: Average rating > 7 and ≤ 8
   - **average**: Average rating > 6 and ≤ 7
   - **bad**: Average rating ≤ 6
3. Activity status is tracked (whether an actor made films that year)

Historical changes in these attributes are tracked using a Type 2 SCD approach with effective dating.

### Code Structure
```bash
models/
├── staging/             # Raw data sources with minimal transformations
│   ├── stg_actor_films.sql
│   ├── stg_actors_current.sql
│   └── _sources.yml
├── intermediate/        # Business logic and transformations
│   ├── int_actor_films_yearly.sql
│   └── int_actor_metrics.sql
└── marts/               # Final presentation layer
    ├── dim_actors.sql
    ├── dim_actors_history.sql
    └── fct_actor_films.sql
```
## Getting Started

### Prerequisites
- dbt (version 1.3.0 or higher)
- Snowflake account
- Environment variables configured:
  - `SNOWFLAKE_ACCOUNT`
  - `SNOWFLAKE_USER`
  - `SNOWFLAKE_PASSWORD`
  - `DBT_SCHEMA`
  - (optional) `SNOWFLAKE_ROLE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_WAREHOUSE`

## Installation and Usage

### Setup

1. Clone this repository:
    ```bash
    git clone https://github.com/vanteddubhaskarreddy/actors-analysis.git
    cd actors-analysis
    ```

2. Install dependencies:
    ```bash
    pip install -r dbt-requirements.txt
    ```

3. Configure environment variables:
    ```bash
    cp dbt.env .env
    # Edit .env with your credentials
    ```

4. Run the pipeline:
    ```bash
    # Process all years
    python process_years.py --start-year 1910 --end-year 2020

    # Or process a specific year
    dbt run --vars '{"current_processing_year": 1914}' --select marts.dim_actors marts.dim_actors_history_scd
    ```

## Data Quality

This project includes comprehensive data quality tests:

- Column presence and type validation
- Rating range constraints (0-10)
- Uniqueness checks for IDs
- Referential integrity across models
- Accepted values for categorical fields

To run tests:
```bash
dbt test
```

## SQLFluff Integration

Code quality is maintained with SQLFluff linting. Check SQL formatting with:
```bash
sqlfluff lint models/
```
