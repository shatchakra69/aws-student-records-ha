.PHONY: help install lint test dev-up dev-down tf-init tf-plan tf-apply tf-destroy cfn-lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

# --- App ---
install: ## Install app dependencies
	cd app && npm install

lint: ## Lint the app
	cd app && npm run lint

test: ## Run app tests
	cd app && npm test

dev-up: ## Start app + MySQL locally (Docker)
	docker compose up --build

dev-down: ## Stop and remove local containers + volumes
	docker compose down -v

# --- Terraform ---
tf-init: ## terraform init
	cd terraform && terraform init

tf-plan: ## terraform plan
	cd terraform && terraform plan

tf-apply: ## terraform apply
	cd terraform && terraform apply

tf-destroy: ## terraform destroy (stops all AWS charges)
	cd terraform && terraform destroy

# --- CloudFormation ---
cfn-lint: ## Lint the CloudFormation template
	cfn-lint cloudformation/student-records.yaml
