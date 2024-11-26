
GIT_TLD=$(shell git rev-parse --show-toplevel)
TF_DIR=$(GIT_TLD)/codebundles/aws-c7n-ec2-health/.test/terraform/
CHDIR=$(shell pwd)/terraform

init:
	terraform init -chdir $(TF_DIR)

create-ec2-instance: init
	terraform apply -auto-approve 

delete-ec2-instance:
	terraform destroy -auto-approve