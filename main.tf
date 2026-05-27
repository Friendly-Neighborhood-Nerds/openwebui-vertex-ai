terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "terraform_backend" {
  name          = "${var.project_id}-tfbackend"
  location      = "EUROPE-WEST6"
  force_destroy = false
  uniform_bucket_level_access = true
}

terraform {
  backend "gcs" {
    bucket = "project-3b05128c-8500-4a22-b1c-tfbackend"
    prefix = "terraform/state"
  }
}
 