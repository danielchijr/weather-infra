#!/bin/bash

# variables
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=""


# No modifications should be made below this point
export ARGOCD_OPTS='--config ~/config/argocd'


cd terraform/stacks/dev/

terraform init

terraform apply -var-file configurations/dev.tfvars -auto-approve

kubectl create namespace argocd
kubectl create namespace dev

mkdir -p ~/config/argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

sleep 120

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argocd login $(kubectl get service argocd-server -n argocd --output=jsonpath='{.status.loadBalancer.ingress[0].hostname}') --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) --insecure

echo "y" | argocd cluster add "$(kubectl config current-context)"

argocd app create weatherapp --repo https://github.com/mountain-digital-systems/argo-examples.git --path weather-webapp --dest-server https://kubernetes.default.svc --dest-namespace dev

argocd app sync argocd/weatherapp

sleep 120

external_ip=$(kubectl get svc weatherapp -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

final_url="$external_ip:3000"

echo $final_url
