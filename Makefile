## COMMON VARS
ENVIRONMENT ?= teamdata
CURRENT_DIR = $(shell pwd)
APP_FOLDER := app

## GIT VARS
GIT_REPO_NAME ?= $(shell basename `git rev-parse --show-toplevel`)
GIT_REPO_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD | sed 's|/|-|g')

# Python vars
LAMBDA_NAME: pi-auth-lambda
BUILD_FOLDER:= build
VENV_FOLDER := venv

## TERRAFORM VARS
TF_FOLDER := terraform
TF_BACKEND_REGION ?= ap-southeast-2
TF_BACKEND_BUCKET := au-com-slyp-$(ENVIRONMENT)-tf-backend
TF_BACKEND_LOCK := tf-backend
TF_BACKEND_KEY := $(GIT_REPO_NAME)/$(GIT_REPO_BRANCH)

###############
# Python Code #
###############
py-clean:
	rm -rf ${BUILD_FOLDER}
	rm -rf ${VENV_FOLDER}

py-build: py-clean
	mkdir ${BUILD_FOLDER}
	mkdir ${VENV_FOLDER}
	python3 -m venv ${VENV_FOLDER}; \
	. ${VENV_FOLDER}/bin/activate; \
	pip install -r app/requirements.txt; \
	deactivate; \
	cp app/index.py ${VENV_FOLDER}/lib/python3.9/site-packages; \
	cd ${VENV_FOLDER}/lib/python3.9/site-packages; \
	zip -r ${CURRENT_DIR}/${BUILD_FOLDER}/pi-auth-lambda.zip *;

#####################
# TERRAFORM TARGETS #
#####################:workdir
tf-deploy: py-clean py-build tf-init tf-vars-ci tf-plan-create tf-apply
tf-destroy: py-clean tf-init tf-vars-ci tf-plan-destroy tf-apply

tf-doc:
	docker run --volume "$(CURRENT_DIR)/$(TF_FOLDER):/terraform-docs" quay.io/terraform-docs/terraform-docs:0.16.0 markdown table --output-file ./README.md --output-mode inject /terraform-docs

tf-lint:
	cd $(TF_FOLDER) && terraform validate
	docker run --rm -v $(CURRENT_DIR)/$(TF_FOLDER):/data -t ghcr.io/terraform-linters/tflint
	docker run --tty --volume $(CURRENT_DIR)/$(TF_FOLDER):/tf --workdir /tf bridgecrew/checkov --directory /tf

tf-init:
	cd $(TF_FOLDER) && terraform init -reconfigure -upgrade=true \
		-backend-config="bucket=$(TF_BACKEND_BUCKET)" \
		-backend-config="key=$(TF_BACKEND_KEY)" \
		-backend-config="region=$(TF_BACKEND_REGION)" \
		-backend-config="dynamodb_table=$(TF_BACKEND_LOCK)" \
		-backend-config="encrypt=true"
	cd $(TF_FOLDER) && terraform workspace select $(ENVIRONMENT) > /dev/null || terraform workspace new $(ENVIRONMENT)

tf-vars-ci:
	echo "" > $(TF_FOLDER)/terraform.tfvars
	echo 'git_branch="$(GIT_REPO_BRANCH)"' >> $(TF_FOLDER)/terraform.tfvars
	echo 'base_dir="$(CURRENT_DIR)"' >> $(TF_FOLDER)/terraform.tfvars

tf-plan-create:
	cd $(TF_FOLDER) && \
		terraform plan -input=false -out terraform.tfplan -var-file=terraform.tfvars

tf-plan-destroy:
	cd $(TF_FOLDER) && \
		terraform plan -input=false -destroy -out terraform.tfplan -var-file=terraform.tfvars

tf-apply:
	cd $(TF_FOLDER) && \
		terraform apply -input=false -auto-approve terraform.tfplan
