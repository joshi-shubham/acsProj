# Final Project: Two-Tier web applicationautomation with Terraform & Ansible
ssh-keygen -t rsa -f project-staging-key<h3 align="center">ACS730 Final Project
    Two-tier Web Application Automation with Terraform & Ansible
</h3>



## Project Outline

The objective of this project is to apply Terraform and Ansible knowledge, usage source control, and continuous integration techniques by deploying a multi-environment infrastructure.

#### Production Environment

| Production VPC | Public        | Private       |
| -------------- | ------------- | ------------- |
| AZ1            | 10.250.0.0/24 | 10.250.3.0/24 |
| AZ2            | 10.250.1.0/24 | 10.250.4.0/24 |
| AZ3            | 10.250.2.0/24 | 10.250.5.0/24 |

#### Staging Environment

| Staging VPC | Public        | Private       |
| ----------- | ------------- | ------------- |
| AZ1         | 10.200.0.0/24 | 10.200.3.0/24 |
| AZ2         | 10.200.1.0/24 | 10.200.4.0/24 |
| AZ3         | 10.200.2.0/24 | 10.200.5.0/24 |



## Deploying Infrastructure with Terraform


1. Create an S3 bucket to store the Terraform state.

	In the AWS management console, create S3 buckets. 
	Note that bucket name should be unique.
	
```sh
xxx-project-backend-prod
xxx-project-backend-staging
```

2. Launch Cloud9 IDE and clone the project code from project's github repository.

   After cloning, you will see two (2) directories.
	```sh
   		ansible 
   		terraform
	```
	
3. Update global variables.

Edit the following file:
```sh
vim	terraform/modules/globalvars/output.tf
```
Set the bucket names for storing Terraform state.
Example:

```sh
output "s3_dev_backend_bucket" {
  value = "xxx-project-backend-staging"
}
output "s3_prod_backend_bucket" {
  value = "xxx-project-backend-prod"
}
```
4. Update the bucket name for storing the Terraform state in the config.tf files.

Edit the following the following files for production environment:
```sh
vim terraform/application/prod/network/config.tf
vim terraform/application/prod/loadbalancer_server/config.tf
vim terraform/application/prod/s3bucket/config.tf
```

Such that they look like the following:
```sh
terraform {
  backend "s3" {
    bucket         = "xxx-project-backend-prod" <---
    key            = "project/application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
```

Edit the following the following files for staging environment:
```sh
vim terraform/application/dev/network/config.tf
vim terraform/application/dev/loadbalancer_server/config.tf
vim terraform/application/dev/s3bucket/config.tf
```

Example:
```sh
terraform {
  backend "s3" {
    bucket         = "xxx-project-backend-staging" <---
    key            = "project/application/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
```

5. Update the bucket name for storing the web images.

	Edit the following files:
	```sh
	vim terraform/application/prod/s3bucket/variables.tf
    vim terraform/application/dev/s3bucket/variables.tf
	```
	Note that bucket name must be unique.
	
	Example for prod:
	```sh
			variable "web-bucket" {
				default     = "xxx-webimages-bucket-prod"
				type		= string
				description = "Bucket-name for web application's bucket"
			}

â€‹	Example for staging (dev):


			variable "web-bucket" {
				default     = "xxx-webimages-bucket-staging"
				type		= string
				description = "Bucket-name for web application's bucket"
			}


6. Deploy the Production VPC network.

   In the Cloud9 IDE from the root directory of the project code, change to *terraform/application/prod/network* directory.

      ```sh
      cd terraform/application/prod/network
      terraform init
      terraform apply -auto-approve -lock=false
      ```

7. Deploy the Production load balancer, EC2 instances, and auto scaling group.

   In the Cloud9 IDE, change from *network* to *prod/loadbalancer_server* directory. Create an SSH key - *project-prod-key*. The SSH key will be used for secure login to the production servers and then deploy.
   
      ```sh
      cd ../loadbalancer_server
      ssh-keygen -t rsa -f project-prod-key
      terraform init
      terraform plan
      terraform apply -auto-approve
      ```
   
8. Deploy the S3 bucket that will store the web image for our web page.
   
   In the Cloud9 IDE, change from *loadbalancer_server* to *prod/s3bucket* directory.
      ```sh
      cd ../s3bucket
      terraform init
      terraform apply -auto-approve
      ```
   
9. Deploy the Staging VPC network.

   In the Cloud9 IDE from the root directory of the project code, change to *terraform/application/dev/network* directory.

      ```sh
      cd terraform/application/dev/network
      terraform init
      terraform apply -auto-approve -lock=false
      ```
10. Deploy the Staging load balancer, EC2 instances, and auto scaling group.

   In the Cloud9 IDE, change from *network* to *dev/loadbalancer_server* directory. Create an SSH key - *project-staging-key*. The SSH key will be used for secure login to the production servers and then deploy.

      ```sh
      cd ../loadbalancer_server
      ssh-keygen -t rsa -f project-staging-key
      terraform init
      terraform plan
      terraform apply -auto-approve
      ```

11. Deploy the S3 bucket that will store the web image for our web page.

   In the Cloud9 IDE, change from *loadbalancer_server* to *dev/s3bucket* directory.
      
```sh
      cd ../s3bucket
      terraform init
      terraform apply -auto-approve
```

   This concludes the infrastructure deployment steps.


## Configuring Web Application Infrastructure with Ansible

1. Go back to the root directory of the project code and change from *terraform/application/dev/s3bucket*  to the *ansible* directory.

```sh
	cd ../../../../ansible
```

2. Copy the server key files that we have generated during the Terraform deployment to the *ansible* directory.

```sh
cp ../terraform/application/prod/loadbalancer_server/project-staging-key .
cp ../terraform/application/dev/loadbalancer_server/project-prod-key .
```


3. Update the variable files.

Edit the following files:
```sh
	vim vars/variable.yml
	vim vars/variable_prod.yml
```

Set the the bucket and key names with the ones we have set during the Terraform deployment. 

Example for variable_prod.yml:
```sh
	s3_bucket_name: xxx-webimages-bucket-prod
	key_path: ./project-prod-key
```

Example for variable_yml:
```sh
	s3_bucket_name: xxx-webimages-bucket-staging
	key_path: ./project-staging-key
```


4. Configure web application on production environment.

```sh
ansible-playbook -i inventory/aws_ec2.yml playbook_prod.yaml
```

5. Configure web application on staging environment.

```sh
ansible-playbook -i inventory/aws_ec2.yml playbook.yaml
```

## Testing

- [x] Browse the production website.

1. Get the production website.

Go to the terraform code directory and check the dns name of production load balancer.
```sh
cd terraform/application/prod/loadbalancer_server
terraform output
```
Copy the ALB-DNS value.

Open a browser and type the URL http://<ALB-DNS>
    

- [x] Browse the Staging website.

Go to the staging (dev) directory and check the dns name of staging load balancer.
```sh
cd ../../dev/loadbalancer_server
terraform output
```
Copy the ALB-DNS value.

Open a browser and type the URL http://<ALB-DNS>


## Infrastructure Cleanup

When you are ready to clean up or destroy the infrastructure, follow these steps.

1. Log back in to Cloud9 IDE and navigate to the root directory then to the Terraform code directory.

```sh
cd terraform
```

2. Destroy Production components.

```sh
cd terraform/application/staging/loadbalancer_server
terraform destroy -auto-approve
```
```sh
cd ../network
terraform destroy -auto-approve -lock=false
```

4. Destroy Staging components.

```sh
cd ../../dev/loadbalancer_server
terraform destroy -auto-approve
```
```sh
cd ../network
terraform destroy -auto-approve -lock=false
```

5. Destroy S3 buckets for web images

  Go to AWS management console > S3 and Empty the web image buckets.

  Example:
  ```sh
  xxx-webimages-bucket-staging
  xxx-webimages-bucket-prod
  ```

  Go back to the root directory of project code and change to terraform directory. Delete the S3 buckets.

```sh
cd terraform/application/prod/s3bucket
terraform destroy -auto-approve
cd ../../dev/s3bucket
terraform destroy -auto-approve
```
