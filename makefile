# Used by `deploy` target, sets AWS deployment defaults, override as required
AWS_ACCOUNT_ID ?= 523443631803
AWS_REGION ?= us-west-2
AWS_AVAILABILITY_ZONES ?= $(AWS_REGION)a,$(AWS_REGION)b
AWS_STACK_NAME ?= vuego-demoapp

# Used by `image`, `push` & `deploy` targets, override as required
IMAGE_REPO ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/vuego-demoapp
IMAGE_TAG ?= latest$(if $(IMAGE_SUFFIX),-$(IMAGE_SUFFIX),)
IMAGE_TAG_FULL := $(IMAGE_REPO):$(IMAGE_TAG)

# Used by `multiarch-*` targets
PLATFORMS ?= linux/arm64,linux/amd64

# Used by `test-api` target
TEST_HOST ?= localhost:4000

# Don't change
FRONT_DIR := frontend
SERVER_DIR := server
REPO_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
GOLINT_PATH := $(REPO_DIR)/bin/golangci-lint

# Set this to false on initial stack creation
CREATE_SERVICE ?= true

.PHONY: help lint lint-fix image push run deploy undeploy clean test test-api test-report test-snapshot watch-server watch-spa .EXPORT_ALL_VARIABLES
.DEFAULT_GOAL := help

help: ## 💬 This help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: $(FRONT_DIR)/node_modules ## 🔎 Lint & format, will not fix but sets exit code on error
	@$(GOLINT_PATH) > /dev/null || curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh
	cd $(SERVER_DIR); $(GOLINT_PATH) run --modules-download-mode=mod ./...
	cd $(FRONT_DIR); npm run lint

lint-fix: $(FRONT_DIR)/node_modules ## 📜 Lint & format, will try to fix errors and modify code
	@$(GOLINT_PATH) > /dev/null || curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh
	cd $(SERVER_DIR); golangci-lint run --modules-download-mode=mod *.go --fix
	cd $(FRONT_DIR); npm run lint-fix

image: ## 🔨 Build container image from Dockerfile
	docker build . --file build/Dockerfile \
	--tag $(IMAGE_TAG_FULL)

push: ## 📤 Push container image to registry
	docker push $(IMAGE_TAG_FULL)

multiarch-image: ## 🔨 Build multi-arch container image from Dockerfile
	docker buildx build . --file build/Dockerfile \
	--platform $(PLATFORMS) \
	--tag $(IMAGE_TAG_FULL)

multiarch-push: ## 📤 Build and push multi-arch container image to registry
	docker buildx build . --file build/Dockerfile \
	--platform $(PLATFORMS) \
	--tag $(IMAGE_TAG_FULL) \
	--push

multiarch-manifest: ## 📤 Build and push multi-arch manifest to registry
	docker manifest create $(IMAGE_TAG_FULL) \
		$(foreach suffix,$(IMAGE_SUFFIXES),$(IMAGE_TAG_FULL)-$(suffix))
	docker manifest push $(IMAGE_TAG_FULL)

run: $(FRONT_DIR)/node_modules ## 🏃 Run BOTH components locally using Vue CLI and Go server backend
	cd $(SERVER_DIR); go run ./cmd &
	cd $(FRONT_DIR); npm run serve

watch-server: ## 👀 Run API server with hot reload file watcher, needs cosmtrek/air
	cd $(SERVER_DIR); air -c .air.toml

watch-frontend: $(FRONT_DIR)/node_modules ## 👀 Run frontend with hot reload file watcher
	cd $(FRONT_DIR); npm run serve

build-frontend: $(FRONT_DIR)/node_modules ## 🧰 Build and bundle the frontend into dist
	cd $(FRONT_DIR); npm run build

deploy: ## 🚀 Deploy to Amazon ECS
	aws cloudformation deploy \
		$(if $(CLOUDFORMATION_ROLE_ARN),--role-arn $(CLOUDFORMATION_ROLE_ARN),) \
		--capabilities CAPABILITY_IAM \
		--template-file $(REPO_DIR)/deploy/aws/ecs-service-template.yaml \
		--stack-name $(AWS_STACK_NAME) \
		--parameter-overrides \
			$(if $(ECS_CLUSTER),ClusterName=$(ECS_CLUSTER),) \
			$(if $(ECS_SERVICE),ServiceName=$(ECS_SERVICE),) \
			CreateService=$(CREATE_SERVICE) \
			AvailabilityZones=$(AWS_AVAILABILITY_ZONES) \
			CreateNATGateways=false \
			CreatePrivateSubnets=false \
			ImageTag=$(IMAGE_TAG)
	@echo "### 🚀 App deployed & available here: http://`aws cloudformation describe-stacks --stack-name $(AWS_STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==\`AlbDnsUrl\`].OutputValue' --output text`"

undeploy: ## 💀 Remove from AWS
	@echo "### WARNING! Going to delete $(AWS_STACK_NAME) 😲"
	aws cloudformation delete-stack --stack-name $(AWS_STACK_NAME)
	aws cloudformation wait stack-delete-complete --stack-name $(AWS_STACK_NAME)

test: $(FRONT_DIR)/node_modules ## 🎯 Unit tests for server and frontend
	cd $(SERVER_DIR); go test -v ./...
	cd $(FRONT_DIR); npm run test

test-report: $(FRONT_DIR)/node_modules ## 📜 Unit tests for server and frontend with report
	go get -u github.com/vakenbolt/go-test-report
	cd $(SERVER_DIR); go test -json ./... | $(shell go env GOPATH)/bin/go-test-report --output test-report.html
	cd $(FRONT_DIR); npm run test-report

test-snapshot: ## 📷 Update snapshots for frontend tests
	cd $(FRONT_DIR); npm run test-update

test-api: $(FRONT_DIR)/node_modules .EXPORT_ALL_VARIABLES ## 🚦 Run integration API tests, server must be running
	$(FRONT_DIR)/node_modules/.bin/newman run tests/postman_collection.json --env-var BASE_URL=$(TEST_HOST)

clean: ## 🧹 Clean up project
	rm -rf $(FRONT_DIR)/dist
	rm -rf $(FRONT_DIR)/node_modules
	rm -rf $(SERVER_DIR)/test*.html
	rm -rf $(FRONT_DIR)/test*.html
	rm -rf $(FRONT_DIR)/coverage
	rm -rf $(REPO_DIR)/bin

# ============================================================================

$(FRONT_DIR)/node_modules: $(FRONT_DIR)/package.json
	cd $(FRONT_DIR); npm install --silent
	touch -m $(FRONT_DIR)/node_modules

$(FRONT_DIR)/package.json:
	@echo "package.json was modified"
