variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for infrastructure (Zurich)"
  type        = string
  default     = "europe-west6"
}

variable "vertex_ai_region" {
  description = "GCP region for Vertex AI model calls (not all regions support Gemini)"
  type        = string
  default     = "europe-north1"
}

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "openwebui"
}

variable "openwebui_image_path" {
  description = "Open WebUI image path on ghcr.io (without registry prefix)"
  type        = string
  default     = "open-webui/open-webui:main"
}

variable "vertex_ai_models" {
  description = "Vertex AI models to expose through LiteLLM"
  type        = list(string)
  default = [
    "gemini-2.5-pro",
    "gemini-2.5-flash",
  ]
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-f1-micro"
}
