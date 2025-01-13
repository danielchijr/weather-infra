#!/bin/bash

export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=""

cd terraform/stacks/dev/

kubectl delete all --all -n dev

kubectl delete all --all -n argocd

terraform destroy -var-file configurations/dev.tfvars -auto-approve