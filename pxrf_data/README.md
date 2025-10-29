# pXRF Data Harmonization

## How to Use the Harmonization Script

The `harmonize_pxrf_data.py` script combines multiple pXRF CSV files into a single harmonized dataframe.

### Prerequisites

Make sure you have Python 3 and pandas installed:

```bash
pip install pandas
```

### Usage

**Option 1: Run with default path (already configured)**

```bash
python3 harmonize_pxrf_data.py
```

The script is pre-configured to look for CSV files in:
`/Users/isaac/Library/CloudStorage/Box-Box/2_academics/Projects/Fossil Spec/Museums`

**Option 2: Specify a different directory**

```bash
python3 harmonize_pxrf_data.py "/path/to/your/csv/files"
```

### What the script does

1. Finds all CSV files in the specified directory
2. Reads each CSV file
3. Adds a `source_file` column to track which file each row came from
4. Combines all dataframes into one
5. Saves the result as `harmonized_pxrf_data.csv` in the same directory
6. Prints a summary and preview of the combined data

### Output

The harmonized data will be saved as:
`/Users/isaac/Library/CloudStorage/Box-Box/2_academics/Projects/Fossil Spec/Museums/harmonized_pxrf_data.csv`

The output file includes:
- All columns from all input CSV files
- A `source_file` column indicating which file each row came from
- All rows from all input files combined
