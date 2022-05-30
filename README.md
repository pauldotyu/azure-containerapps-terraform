# azure-containerapps-terraform

This repos is a demonstration of how to use the new Terraform [AzApi](https://registry.terraform.io/providers/Azure/azapi/latest/docs) provider to deploy a "day 0" resource like [Azure Container Apps](https://azure.microsoft.com/en-us/services/container-apps/). This repos will deploy a sample [hello world](https://github.com/pauldotyu/dapr-demos) microservice app which uses Dapr for service invocation.

AzApi will allow you to use [Azure Resource Manager (or Bicep)](https://docs.microsoft.com/en-us/azure/templates/) template APIs and schemas to deploy Azure resources while also taking advantage of all the good things Terraform provides around state management and resource deployment dependency tracking.

For this demo, you can refer to the following Bicep docs for provisioning Azure Container Apps:

- https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/managedenvironments?tabs=bicep
- https://docs.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps?tabs=bicep

To run this demo:

- Make sure you have the Terraform CLI installed
- Run `terraform init` to initialize the directory
- Run `terraform apply`

To test the app:

- Navigate to your `greeting-service` container app in the Azure Portal
- Locate and copy the ingress URL
- Paste the `greeting-service` ingress URL to a browser widow and append `/greet` to the end
