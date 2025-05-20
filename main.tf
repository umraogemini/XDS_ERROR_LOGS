provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_logging_metric" "xds_error_logs_alerts" {
  name        = "XDS_Error_Logs_Alerts"
  description = "Tracks XDS-related errors and warnings"
  project     = var.project_id

  filter = <<EOT
resource.type="k8s_container" 
AND severity=("ERROR" OR "INFO") 
AND (  
  textPayload:"RD10001" OR
  textPayload:"RD10014" OR
  textPayload:"RD10015" OR
  textPayload:"RD10016" OR
  textPayload:"RD10024" OR
  textPayload:"RD10034" OR
  textPayload:"RD10035" OR
  textPayload:"RD10044" OR
  textPayload:"RD10094" OR
  textPayload:"RD10099"
)
EOT

  metric_descriptor {
    metric_kind = "CUMULATIVE"  # Counter type
    value_type  = "INT64"
    unit        = "1"
  }
}

data "google_secret_manager_secret_version" "xmatters_auth" {
  secret  = "xmatters_auth_passwd"
  project = var.project_id
}

resource "google_monitoring_notification_channel" "xmatters_webhook" {
  display_name = "xMatters Webhook"
  type         = "webhook_basicauth"
  project      = var.project_id

  labels = {
    url      = var.xmatters_webhook_url
    username = "BC000010001"
  }

  sensitive_labels {
    password = data.google_secret_manager_secret_version.xmatters_auth.secret_data
  }
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification For GCP TF"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_alert_policy" "xds_error_logs_alerts" {
  display_name = "XDS_Error_Logs_Alerts"
  combiner     = "OR"
  enabled      = true
  project      = var.project_id

  notification_channels = [
    google_monitoring_notification_channel.xmatters_webhook.id
  ]

  conditions {
    display_name = "XDS_Error_Logs_Alerts"
    condition_threshold {
      filter = <<EOT
resource.type="k8s_container" AND metric.type="logging.googleapis.com/user/${google_logging_metric.xds_error_logs_alerts.name}"
EOT
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period     = "60s"
        cross_series_reducer = "REDUCE_SUM"
        per_series_aligner   = "ALIGN_DELTA"
      }
      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "604800s"  # 7 days
  }

  documentation {
    content = <<EOT
{
  "@key": "6b89d199-64cd-4ec4-ab7d-7514c92283be",
  "@version": "alertapi-0.1",
  "@type": "ALERT",
  "object": "Testobject",
  "severity": "CRITICAL",
  "text": "xMatters ERROR Test"
}
EOT
    mime_type = "text/markdown"
  }
}
