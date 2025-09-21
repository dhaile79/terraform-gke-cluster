# ==========================================================
# Makefile for Terraform GKE Cluster
# ==========================================================
# This Makefile provides shortcuts for common Terraform workflows.
# It uses terraform.tfvars for normal safe apply,
# and destroy.tfvars to disable deletion_protection for teardown.
# Includes a 2-phase apply: core (GKE) first, then the rest (HPA/VPA, etc.).
# ==========================================================

SHELL := /bin/bash

# -------- Variables --------
TF_DIR      := .
TF          := terraform
TFVARS      := terraform.tfvars
DESTROYVARS := destroy.tfvars

# Optional overrides when calling make (e.g. make get-credentials PROJECT=foo REGION=europe-west2 CLUSTER=bar)
PROJECT ?=
REGION  ?=
CLUSTER ?=

# -------- Default target --------
.PHONY: help
help:
	@echo "Terraform GKE Cluster Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make init           - Initialize Terraform providers and modules"
	@echo "  make fmt            - Format Terraform files"
	@echo "  make validate       - Validate Terraform configuration"
	@echo "  make plan-core      - Plan only GKE (targets module.gke)"
	@echo "  make apply-core     - Apply only GKE plan"
	@echo "  make plan-all       - Plan full stack (after cluster exists)"
	@echo "  make apply-all      - Apply full stack plan"
	@echo "  make get-credentials [PROJECT=.. REGION=.. CLUSTER=..] - Fetch kubeconfig for the cluster"
	@echo "  make plan-destroy   - Plan with deletion_protection=false (uses destroy.tfvars)"
	@echo "  make destroy        - Apply destroy plan"
	@echo "  make clean          - Remove .terraform and plan files"

# -------- Core Terraform hygiene --------
.PHONY: init
init:
	$(TF) -chdir=$(TF_DIR) init -upgrade

.PHONY: fmt
fmt:
	$(TF) -chdir=$(TF_DIR) fmt -recursive

.PHONY: validate
validate:
	$(TF) -chdir=$(TF_DIR) validate

# -------- Phase 1: Cluster only (prevents kubernetes provider from racing) --------
.PHONY: plan-core
plan-core:
	$(TF) -chdir=$(TF_DIR) plan -var-file=$(TFVARS) -target=module.gke -out=plan-core.tfplan

.PHONY: apply-core
apply-core:
	$(TF) -chdir=$(TF_DIR) apply -auto-approve plan-core.tfplan

# -------- Phase 2: Everything after the cluster exists --------
.PHONY: plan-all
plan-all:
	$(TF) -chdir=$(TF_DIR) plan -var-file=$(TFVARS) -out=plan-all.tfplan

.PHONY: apply-all
apply-all:
	$(TF) -chdir=$(TF_DIR) apply -auto-approve plan-all.tfplan

# -------- Kubeconfig helper (works if you pass PROJECT/REGION/CLUSTER or have them set) --------
.PHONY: get-credentials
get-credentials:
	@if [[ -z "$(PROJECT)" || -z "$(REGION)" || -z "$(CLUSTER)" ]]; then \
		echo "Usage: make get-credentials PROJECT=<id> REGION=<region> CLUSTER=<name>"; \
		exit 2; \
	fi
	gcloud container clusters get-credentials $(CLUSTER) --region $(REGION) --project $(PROJECT)

# -------- Teardown (disable deletion protection via destroy.tfvars) --------
.PHONY: plan-destroy
plan-destroy:
	$(TF) -chdir=$(TF_DIR) plan -var-file=$(DESTROYVARS) -out=destroy.tfplan

.PHONY: destroy
destroy:
	$(TF) -chdir=$(TF_DIR) apply -auto-approve destroy.tfplan

# -------- Cleanup --------
.PHONY: clean
clean:
	rm -rf .terraform .terraform.lock.hcl plan*.tfplan destroy.tfplan

