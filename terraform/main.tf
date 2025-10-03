terraform {
  required_version = "1.13.3"
}


provider "google" {
  project = var.project_id
  region  = var.region
}



resource "google_pubsub_topic" "cicd_events" {
  name = "ci-cd-events"
}

resource "google_pubsub_subscription" "ci_cd_subscription" {
  name  = "cicd_subscription"
  topic = google_pubsub_topic.cicd_events.name

  push_config {
    push_endpoint = "${google_cloud_run_service.fastapi.status[0].url}/publish"
    oidc_token {
      service_account_email = google_service_account.pubsub_sa.email
    }
  }
}


resource "google_service_account" "pubsub_sa" {
  account_id   = "pubsub-notifier"
  display_name = "Pub/Sub Notifier Service Account"
}

resource "google_cloud_run_service" "fastapi" {
  name     = "fastapi-pubsub"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/fastapi-pubsub/fastapi-pubsub:latest"
        ports {
          container_port = 8000
        }
        env {
          name  = "SLACK_WEBHOOK_URL"
          value = var.slack_webhook_url
        }
      }

    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}


resource "google_artifact_registry_repository" "fastapi-pubsub" {
  provider      = google
  location      = var.region
  repository_id = "fastapi-pubsub"
  description   = "Docker repo for FastAPI CI/CD app"
  format        = "DOCKER"
}


resource "google_cloud_run_service_iam_member" "invoker" {
  service  = google_cloud_run_service.fastapi.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_sa.email}"
}
