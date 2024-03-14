# Tutorial - Learn Terraform

## Installing Terraform
<p>To install latest Terraform version, make it by clicking [here](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)</p> <br>
## Terraform - Format and Validate Terraform code
```
terraform fmt #format code per HCL canonical standard
terraform validate #validate code for syntax
terraform validate -backend=false #validate code skip backend validation
```
## Initialize your Terraform working directory
```
terraform init
```
## Plan, Deploy and Cleanup Infrastructure
```
terraform plan
terraform apply
```
### Destroy IaC
```
terraform destroy 
```
Or with outoprove
```
terraform destroy --auto-approve
```
