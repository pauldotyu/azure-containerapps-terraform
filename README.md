# azure-containerapps-terraform

This repos is a demonstration of how to use the new Terraform [AzApi](https://registry.terraform.io/providers/Azure/azapi/latest/docs) provider to deploy a "day 0" resource like [Azure Container Apps](https://azure.microsoft.com/en-us/services/container-apps/). This repos will deploy a sample [hello world](https://github.com/pauldotyu/dapr-demos) microservice app which uses Dapr for service invocation.

AzApi will allow you to use [Azure Resource Manager (or Bicep)](https://docs.microsoft.com/en-us/azure/templates/) template APIs and schemas to deploy Azure resources while also taking advantage of all the good things Terraform provides around state management and resource deployment dependency tracking.

For this demo, you can refer to the following Bicep docs for provisioning Azure Container Apps:

- https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/managedenvironments?tabs=bicep
- https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps?tabs=bicep

## Run this demo:

- Make sure you have the Terraform CLI installed
- Run `terraform init` to initialize the directory
- Run `terraform apply`

## Test the app:

- Navigate to your `greeting-service` container app in the Azure Portal
- Locate and copy the ingress URL
- Paste the `greeting-service` ingress URL to a browser widow and append `/greet` to the end

## Configure CI/CD with GitHub Actions:

- Create a new service principal

  ```sh
  az ad sp create-for-rbac \
  --name <SERVICE_PRINCIPAL_NAME> \
  --role "contributor" \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME> \
  --sdk-auth
  ```

- Link your container app with your GitHub repo (run this for each container app)

  ```sh
  az containerapp github-action add \
  --repo-url "https://github.com/<OWNER>/<REPOSITORY_NAME>" \
  --context-path <DOCKERFILE_PATH> \
  --branch <BRANCH_NAME> \
  --name <CONTAINER_APP_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --registry-url <URL_TO_CONTAINER_REGISTRY> \
  --registry-username <REGISTRY_USER_NAME> \
  --registry-password <REGISTRY_PASSWORD> \
  --service-principal-client-id <CLIENT_ID> \
  --service-principal-client-secret <CLIENT_SECRET> \
  --service-principal-tenant-id <TENANT_ID> \
  --login-with-github
  ```

## Troubleshooting Tips

- If you encounter an error on delete with the following error message:

  ```text
  │ Error: deleting "Resource: (ResourceId \"/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-dynamicamoeba/providers/Microsoft.App/managedEnvironments/env-dynamicamoeba\" / Api Version \"2022-03-01\")": missing error information
  ```

  You need to go and check to make sure you did not manually create a container app in the managed environment outside of Terraform. If you did, you need to manually delete the container app.
