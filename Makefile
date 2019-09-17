CDK := $(shell nodenv which cdk)

.phony: build
build: build-api build-ui ## Build all Components

.phony: deploy
deploy: deploy-paas deploy-ui ## Deploy all Components

.phony: check
check: ## Check PAAS Parameters
	@cd paas && direnv exec ./ $(CDK) ls

.phony: diff
diff: ## Check PAAS diff
	@cd paas && direnv exec ./ $(CDK) diff

.phony: build-api
build-api: ## Make Lambda API Components
	@cd api && make

.phony: build-ui
build-ui: ## Build the UI Components
	@cd ui && yarn && yarn build

.phony: deploy-paas
deploy-paas: build-api ## Deploy the PAAS components
	@cd paas && direnv exec ./ $(CDK) deploy --require-approval never

.phony: deploy-ui
deploy-ui: build-ui ## Deploy the UI the the S3 Bucket in the parameter store
	@aws s3 sync --delete ui/build/ s3://$(shell aws ssm get-parameter --name /site/bucket/name | jq -r '.Parameter.Value')

.phony: clean
clean: ## Remove all build artifacts
	@cd api && make clean
	@cd ui && rm -rf build

.phony: help
help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
