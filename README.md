# 🚀 Terraform GKE Cluster (Modular, Secure, Scalable)

This repository provisions a **Google Kubernetes Engine (GKE)** cluster using **Terraform**.  
It demonstrates modern **Infrastructure as Code (IaC)** practices: modular design, security-first defaults, automation with Makefiles, and lifecycle awareness (pre-cluster vs post-cluster setup).  

---

## ✨ Key Features

- **Idempotent IaC** → Terraform ensures infrastructure matches desired state  
- **Modular design** → `gke/`, `hpa/`, `vpa/` modules for composability  
- **Safe defaults** → `deletion_protection = true` unless overridden in `destroy.tfvars`  
- **Makefile automation** → simplified developer workflows  
- **Workload Identity (WI)** → secure Pod-to-GCP IAM access (must be enabled at cluster creation)  
- **Secret Manager integration** → store and retrieve secrets securely from workloads  
- **Scalability** → Horizontal and Vertical Pod Autoscalers as opt-in modules  

---

## 📂 Repository Structure



terraform-gke-cluster/ ├── infra/ │ └── terraform/ │ ├── main.tf │ ├── variables.tf │ ├── outputs.tf │ ├── terraform.tfvars │ ├── destroy.tfvars │ └── Makefile ├── modules/ │ ├── gke/ │ │ ├── main.tf │ │ └── variables.tf │ ├── hpa/ │ └── vpa/ └── docs/ └── diagram.png # (coming soon) Architecture overview


---

## ✅ Prerequisites

Install locally:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) ≥ **1.6**  
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) (authenticated to your GCP project)  
- [kubectl](https://kubernetes.io/docs/tasks/tools/)  
- GCP project with:
  - **Billing enabled**
  - APIs enabled:  
    - `compute.googleapis.com`  
    - `container.googleapis.com`  
    - `artifactregistry.googleapis.com`  
    - `containeranalysis.googleapis.com`  

---

## ⚙️ Authentication Options

Terraform uses the **Google provider**, which authenticates using `gcloud` credentials.  
You can work in **two modes**:

### 🔹 Test/Demo (using your Google user account)
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID


Terraform will pick up your user credentials automatically.
⚠️ Fine for learning and demos, but not recommended for production.

🔹 Production (using a dedicated Service Account)

Create a Service Account:

gcloud iam service-accounts create terraform-sa \
  --display-name "Terraform Service Account"


Grant IAM roles (least privilege):

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member "serviceAccount:terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role roles/container.admin \
  --role roles/compute.networkAdmin \
  --role roles/iam.serviceAccountUser


Download a key (for CI/CD pipelines):

gcloud iam service-accounts keys create terraform-sa-key.json \
  --iam-account terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com


Authenticate with Service Account:

gcloud auth activate-service-account \
  terraform-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --key-file=terraform-sa-key.json
gcloud config set project YOUR_PROJECT_ID


✅ Now Terraform runs under the Service Account, not your personal user.

⚙️ Configuration

Define values in terraform.tfvars:

project_id            = "YOUR_PROJECT_ID"
region                = "europe-west2"
cluster_name          = "demo-gke-cluster"
node_count            = 3
node_machine_type     = "e2-medium"
node_disk_size_gb     = 30
node_disk_type        = "pd-standard"
deletion_protection   = true   # always true in prod


For teardown, override in destroy.tfvars:

deletion_protection = false


⚠️ Important – Workload Identity requirement
The cluster must be created with Workload Identity enabled. Without this, Pods will only run as the node's default compute service account and will not be able to read from Secret Manager or access GCP APIs with annotated Kubernetes Service Accounts.

🔧 Example: Enabling Workload Identity in Terraform

This module already injects Workload Identity into your cluster, but if building from scratch, ensure your Terraform includes the following:

Cluster-level (required)
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  deletion_protection = var.deletion_protection
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode     = "VPC_NATIVE"
  ip_allocation_policy {}

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  release_channel {
    channel = "REGULAR"
  }

  # ✅ Required for Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

Node pool-level (required)
resource "google_container_node_pool" "general" {
  name       = "${var.cluster_name}-general"
  location   = var.region
  project    = var.project_id
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    # ✅ Required for Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      role = "general"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
}


➡️ Without these blocks, Pods will fall back to authenticating as the node service account (PROJECT_NUMBER-compute@developer.gserviceaccount.com) → leading to PERMISSION_DENIED when accessing APIs like Secret Manager or Pub/Sub.

📖 Usage with Makefile
Initialize
make init

Plan & Apply (safe defaults)
make plan-core
make apply-core
make plan-all
make apply-all

Teardown (disable deletion protection)
make plan-destroy
make destroy

Clean local state
make clean

🔍 Validation

After cluster creation:

make get-credentials PROJECT=YOUR_PROJECT_ID REGION=europe-west2 CLUSTER=demo-gke-cluster

kubectl get nodes
kubectl top nodes

🔐 Security & Cost Optimisation
✅ Private nodes (no external IPs)
✅ Deletion protection (enabled by default)
✅ Workload Identity must be enabled (to allow Secret Manager / GCP API access from pods)
✅ Preemptible/spot nodes optional for dev/test
✅ Node autoscaling to control cost
🔑 Workload Identity + Secret Manager

Workload Identity securely maps Kubernetes Service Accounts (KSAs) to Google IAM Service Accounts (GSAs).
This removes the need for long-lived keys and ensures Pods can only access what IAM permits.

⚠️ Cluster Creation Requirement
To use Workload Identity, the GKE cluster must be created with:

workload_identity_config at the cluster level
workload_metadata_config { mode = "GKE_METADATA" } at the node pool level
🛠 Pre-Cluster Provisioning (GCP-level)

Create GSA:

gcloud iam service-accounts create gke-workload \
  --project=YOUR_PROJECT_ID


Grant IAM role:

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member "serviceAccount:gke-workload@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/secretmanager.secretAccessor"


Store secret in Secret Manager:

echo -n "super-secret-password" | \
  gcloud secrets create db-password --data-file=-

🛠 Post-Cluster Provisioning (Kubernetes-level)

Create namespace:

kubectl create namespace apps


Create KSA:

kubectl create serviceaccount gke-app -n apps


Annotate KSA with GSA:

kubectl annotate serviceaccount gke-app \
  -n apps \
  iam.gke.io/gcp-service-account=gke-workload@YOUR_PROJECT_ID.iam.gserviceaccount.com


Run Pod that consumes secret:

apiVersion: v1
kind: Pod
metadata:
  name: secret-test
  namespace: apps
spec:
  serviceAccountName: gke-app
  containers:
  - name: sm-test
    image: google/cloud-sdk:slim
    command: ["sh", "-c", "gcloud secrets versions access latest --secret=db-password"]


✅ The Pod authenticates via Workload Identity → GSA → Secret Manager, without exposing service account keys.

🎯 Next Steps
Add OPA/Gatekeeper for policy enforcement
Bootstrap GitOps with ArgoCD App-of-Apps
Enforce Network Policies for workload isolation
Add FinOps dashboards to monitor GKE spend
👔 Why this repo matters

This project was built to experiment with real-world GCP scenarios and capture lessons you only learn by running infrastructure in the cloud.

Test failures (e.g. quota limits, tiny node types) became learning opportunities for designing resilient clusters.
IaC is optimized for repeatability and clarity — from Makefile automation to modular Terraform.
Balances learning by doing with production-grade patterns: workload identity instead of key files, deletion protection by default, and safe teardown workflows.

---
