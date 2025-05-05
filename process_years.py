#!/usr/bin/env python

import subprocess
import argparse

def process_year(year):
    """Process a specific year of actor data using dbt"""
    print(f"Processing year {year}...")
    cmd = [
        "dbt", "run", 
        "--vars", f'{{"current_processing_year": {year}}}',
        "--select", "marts.dim_actors marts.dim_actors_history_scd"
    ]
    subprocess.run(cmd, check=True)

def main():
    parser = argparse.ArgumentParser(description='Process actor data year by year')
    parser.add_argument('--start-year', type=int, default=1910, 
                        help='Starting year to process')
    parser.add_argument('--end-year', type=int, default=2020,
                        help='Ending year to process')
    
    args = parser.parse_args()
    
    # First run the staging and intermediate models
    subprocess.run(["dbt", "run", "--select", "staging intermediate"], check=True)
    
    # Then process each year incrementally
    for year in range(args.start_year, args.end_year + 1):
        process_year(year)
    
    print("Completed processing all years!")

if __name__ == "__main__":
    main()