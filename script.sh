#!/bin/bash

# Define variables
file_project="<nome-do-csv>"
organization="<nome-da-organização>"
novo_tenant="<nome-do-novo-tenant>"
pat="<azure-devops-personal-access-tokens>"

# Check if tenants_inalterados.csv exists and is not empty; if not, create it and add headers
if [ ! -f tenants_inalterados.csv ]; then
    if [ ! -s tenants_inalterados.csv ]; then
        echo "projects,nome_do_endpoint,endpoint_id,tenant_id,motivo" >> tenants_inalterados.csv
    fi
fi

# Check if tenants_alterados.csv exists and is not empty; if not, create it and add headers
if [ ! -f tenants_alterados.csv ]; then
    if [ ! -s tenants_alterados.csv ]; then
        echo "projects,nome_do_endpoint,antigo_tenant,tenant_atualizado" >> tenants_alterados.csv
    fi
fi

# Create the header for authentication
token=$(echo -n ":$pat" | base64)

# Read each project from the file
while IFS=";" read -r projects; do
    # Fetch the current service endpoints for the project
    json_project=$(curl -s -H "Authorization: Basic $token" -H "Content-Type: application/json" "https://dev.azure.com/$organization/$projects/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4")

    # Get the count of service endpoints
    count=$(echo "$json_project" | jq -r '.count')

    # Iterate through each service endpoint
    for ((i=0; i<$count; i++)); do 
        endpoint=$(echo "$json_project" | jq -r ".value[$i].id")

        uri="https://dev.azure.com/$organization/$projects/_apis/serviceendpoint/endpoints/$endpoint?api-version=7.1-preview.4"

        # Fetch the current service connection details
        json_project2=$(curl -s -H "Authorization: Basic $token" -H "Content-Type: application/json" "$uri")
        antigo_tenant=$(echo "$json_project2" | jq -r '.authorization.parameters.tenantid')
        nome_endpoint=$(echo "$json_project2" | jq -r '.name')

        manual_valid=$(echo "$json_project2" | jq -r '.data.creationMode')

        # Check if the endpoint is created automatically or already has the new tenant ID
        if [ "$manual_valid" == "Automatic" ] || [ "$antigo_tenant" == "$novo_tenant" ]; then
            if [ "$manual_valid" == "Automatic" ]; then
                echo -e "O endpoint $nome_endpoint foi criado de forma automatica, não é possivel atualizar o tenant id.\n"
                echo "$projects,$nome_endpoint,$endpoint,$antigo_tenant,endpoint automatico" >> tenants_inalterados.csv
            else
                echo -e "O endpoint $nome_endpoint já está no novo tenant, não há necessidade de atualizar o tenant id.\n"
                echo "$projects,$nome_endpoint,$endpoint,$antigo_tenant,endpoint ja atualizado" >> tenants_inalterados.csv
            fi
        else
            # Update the tenantid in the fetched JSON
            update_tenantid=$(echo "$json_project2" | jq --arg novo_tenant "$novo_tenant" '.authorization.parameters.tenantid = $novo_tenant')
            
            # Send the updated JSON back via PUT request
            curl -X PUT "$uri" -H "Authorization: Basic $token" -H "Content-Type: application/json" -d "$update_tenantid" >/dev/null 2>&1

            # Validate the tenant ID change
            tenantid_updated=$(curl -s -H "Authorization: Basic $token" -H "Content-Type: application/json" "$uri")
            tenant_atualizado=$(echo "$tenantid_updated" | jq -r '.authorization.parameters.tenantid')

            # Check if the tenant ID was updated successfully
            if [ "$antigo_tenant" == "$tenant_atualizado" ]; then
                echo -e "Tenant não foi alterado para:\nProjeto: $projects\nEndpoint Name: $nome_endpoint\nEndpoint ID: $endpoint\n"
                echo "$projects,$nome_endpoint,$endpoint,$tenant_atualizado,erro na atualizao do tenant" >> tenants_inalterados.csv
            else
                echo -e "Tenant alterado com sucesso para o projeto $projects e endpoint $nome_endpoint\n" 
                echo "$projects,$nome_endpoint,$antigo_tenant,$tenant_atualizado" >> tenants_alterados.csv
            fi
        fi
    done
done < $file_project