---


---


### Description

This repository builds up a weather app within an EKS cluster with ArgoCD used for deployment. The build time can take 15 to 30 minutes for the resources to be spun up.

---

### Requirements

| Dependency | Version |
| ---------- | ------- |
| Terraform  | v1.5.5  |
| AWS-CLI    | 2.13.9  |
| Python     | 3.11.4  |
| Kubectl    |         |
| Argocd CLI |         |
|            |         |

---

### Instructions


1. Modify the values of the variables in the build_script.sh and destroy_script.sh as desired, and run the below commands to execute the desired script.

   ```
   chmod +x build_script.sh
   ```
   ```
   ./build_script.sh
   ```
2. This script creates charged resources, be sure to destroy the architecture when no longer in use to avoid unplanned charges. This can be done by running the commands

   ```
   chmod +x destroy_script.sh
   ```
   ```
   ./destroy_script.sh
   ```
3. On occasion that all resources are taking too long to destroy or not completely destroyed, it is advised to manually destroy them, as there might be loadbalancers or network interfaces that might have been missed by terraform or created as a service by eks and so not managed by terraform. This can make it impossible for terraform to destroy the vpc.
