Prerequisites

| Tech      | Version |
| --------- | ------- |
| Terraform | ~>v1.0  |
| AWS CLI   |         |





terraform init

terraform plan -var-file configurations/dev.tfvars

terraform apply -var-file configurations/dev.tfvars -auto-approve


terraform destroy -var-file configurations/dev.tfvars -auto-approve
