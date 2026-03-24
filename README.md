# Open WebUI on GCP with Vertex AI

Deploys [Open WebUI](https://github.com/open-webui/open-webui) on Google Cloud Run, backed by **Vertex AI Gemini models** via a **LiteLLM proxy**. Infrastructure runs in **europe-west6 (Zurich)** by default; Vertex AI calls can target a separate region.

## Architecture

```
User ──▶ Cloud Run (Open WebUI, public) ──▶ Cloud Run (LiteLLM, internal) ──▶ Vertex AI
                │                                    │
                └──────── VPC ───────────────────────┘
                           │
                     Cloud SQL PostgreSQL
```

| Component | Purpose |
|---|---|
| **Open WebUI** | Chat UI with user auth, chat history, model picker |
| **LiteLLM** | OpenAI-compatible proxy → Vertex AI; handles OAuth2 token refresh via service account |
| **Cloud SQL** | PostgreSQL for persistent user data & chat history |
| **Artifact Registry** | Remote repository proxying ghcr.io container images |
| **VPC + Connector** | Private networking for Cloud SQL and internal service communication |
| **Secret Manager** | Stores LiteLLM config, master key, DB credentials, session secret |

---

## Prerequisites (MANUAL — before Terraform)

```bash
# Install Terraform >= 1.5
# https://developer.hashicorp.com/terraform/install

# Install gcloud CLI
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login
gcloud auth application-default login

# Create a project (or use existing) — MUST have billing enabled
gcloud projects create MY_PROJECT_ID --name="Open WebUI"
gcloud config set project MY_PROJECT_ID

# Link a billing account (required for Cloud Run, Cloud SQL, Vertex AI)
gcloud billing accounts list
gcloud billing projects link MY_PROJECT_ID --billing-account=XXXXXX-XXXXXX-XXXXXX
```

### Enable Vertex AI model access (MANUAL)

Open Vertex AI Studio in the GCP Console and send a test prompt to activate Gemini access for your project:

```
https://console.cloud.google.com/vertex-ai/studio/multimodal?project=MY_PROJECT_ID
```

This is a one-time step — Terraform cannot automate the ToS acceptance.

> **Note:** Not all regions support Gemini models. The `vertex_ai_region` variable lets you
> route model calls to a supported region independently of where your infrastructure runs.
> Check [Vertex AI regional availability](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations) for current support.

---

## Deploy with Terraform

```bash
cd webui-demo

# Create your tfvars
cat > l.auto.tfvars <<EOF
project_id       = "MY_PROJECT_ID"
vertex_ai_region = "europe-north1"   # Region for Vertex AI model calls
EOF

terraform init
terraform plan
terraform apply
```

Deployment takes **~10–15 minutes** (Cloud SQL creation is slow).

### Variables

| Variable | Default | Description |
|---|---|---|
| `project_id` | — (required) | GCP project ID |
| `region` | `europe-west6` | Infrastructure region (Cloud Run, Cloud SQL, VPC) |
| `vertex_ai_region` | `europe-north1` | Region for Vertex AI Gemini API calls |
| `vertex_ai_models` | `["gemini-2.5-pro", "gemini-2.5-flash"]` | Models to expose through LiteLLM |
| `resource_prefix` | `openwebui` | Prefix for all resource names |
| `db_tier` | `db-f1-micro` | Cloud SQL machine tier |

---

## First login (MANUAL — after Terraform)

1. Copy the `openwebui_url` from the Terraform output.
2. Open it in your browser.
3. **Create your admin account** on the signup page (first user becomes admin).
4. Start chatting — Gemini models are available in the model picker.

---

## What Terraform manages

- GCP API enablement (10 APIs including aiplatform, run, compute, secretmanager, etc.)
- Two service accounts with least-privilege IAM roles
- VPC + Subnet (with Private Google Access) + VPC Connector
- Private Services Access (Cloud SQL peering)
- Cloud SQL PostgreSQL instance, database, user
- Artifact Registry remote repository (proxying ghcr.io)
- Secret Manager secrets (LiteLLM config YAML, master key, DB URL, session key)
- Cloud Run: LiteLLM proxy (internal-only ingress)
- Cloud Run: Open WebUI (public ingress)

## Cost estimate (idle)

| Resource | ~Monthly cost |
|---|---|
| Cloud SQL db-f1-micro | ~$10 |
| Cloud Run × 2 (scale to zero) | $0 when idle |
| VPC Connector (min 2 instances) | ~$7 |
| Secret Manager | < $1 |
| **Total idle** | **~$18/month** |

Usage costs depend on Vertex AI model pricing per token.

## Cleanup

```bash
terraform destroy
```

> `deletion_protection` is set to `false` on Cloud SQL for easy teardown. Set to `true` for production.
