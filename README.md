<h3 align="center">
<img src="https://cdn.rawgit.com/odb/official-bash-logo/master/assets/Logos/Identity/PNG/BASH_logo-transparent-bg-color.png">
</h3>

# Script Description

This script is designed to change tenant information for a project endpoint in Azure DevOps.

## Prerequisites

- Bash shell
- CSV file in the same directory as the script

## Variables

- `file_project`: The name of the CSV file to be processed.
- `organization`: The name of the organization.
- `novo_tenant`: The new tenant ID.
- `pat`: Personal Access Token for authentication.

## CSV File
Insert the list of projects in the organization that need to have their tenant IDs changed.

To create the CSV file, use the following command in the terminal:
```bash
touch file-example.csv
```

Insert the name in the CSV file as follows:
```bash
Project1
Project2
Project3
```

## Usage

1. Ensure you have a CSV file in the same directory as the script.
2. Give permission to run:
    ```bash
    chmod +x script.sh
    ```
3. Run the script using the following command:
    ```bash
    ./script.sh
    ```

## Script Details

The script will generate two CSV files: `tenants_inalterados.csv` and `tenants_alterados.csv`. The first file records all endpoints where the tenant ID was not changed, while the second file shows all endpoints where the tenant ID was changed.