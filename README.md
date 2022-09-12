1-Launch a Cloud9 Instance

2-Install Terraform:

    sudo yum install -y yum-utils
    
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    
    sudo yum -y install terraform
    
    terraform -v
    
3-Install Terragrunt:

    wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.6/terragrunt_linux_amd64
    
    sudo mv terragrunt_linux_amd64 /usr/bin/terragrunt
    
    chmod +x /usr/bin/terragrunt
    
    terragrunt -v
    
4-Create a S3 bucket(terraform-state-store-2022) and set the value in environments/test/inputs.hcl

5-Create a dynamodb table named terraform-lock-table with Partition Key - "LockID"

6-Create ECR registries for test,staging and production using terragrunt

7-use the Dockerfile given in the application_code repo(https://github.com/vinycoolguy2015/application_code) to build an image and push it to the ECR registries

8-Create all the other application resources(VPC,Security Groups,IAM roles,WAF,ECS Cluster/Service, ALB and CodePipeline) using terragrunt.

9-Make some changes to the code on your local machine, build a new image and push it to the ECR registries.This will trigger the codepipline.

10-Make some changes to the code and raise a PR for https://github.com/vinycoolguy2015/application_code. When the PR is merged to the test,staging or main branch, it will trigger respective github workflow to create a new image and push it to the respective ECR. Once the image is pushed to ECR,the respective codepipeline will be triggered for Blue/Green ECS deployment.
