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
    
4-Create a S3 bucket named terraform-state-store-2022

5-Create a dynamodb table named terraform-lock-table with Partition Key - "LockID"

6-Create ECR for test,staging and production.use the Dockerfile given in the application_code repo to build an image and push it to the registries

7-Create all the other application resources

8-Make some changes to the code, build a new image and push it to the ECR registries.This will trigger the codepipline
