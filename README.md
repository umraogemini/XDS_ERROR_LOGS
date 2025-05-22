# XDS_ERROR_LOGS


documentation {
  content = jsonencode({
    "severity"         = "WARNING",
    "policy_name"      = "VM High Memory Alert",
    "condition_name"   = "Kubernetes Node - Memory allocatable utilization",
    "description"      = "Utilization is above threshold",
    "project_id"       = var.project_id,
    "metric"           = "kubernetes.io/node/memory/allocatable.utilization",
    "cluster_name"     = "${resource.label.cluster_name}",
    "node_name"        = "${resource.label.node_name}",
    "location"         = "${resource.label.location}",
    "memory_type"      = "${resource.label.memory_type}",
    "component"        = "${resource.label.component}",
    "actual_value"     = "${metric.value.double_value}",
    "threshold_value"  = "0.5",
    "start_time"       = "${start_time}",
    "duration"         = "4 minutes",
    "@type"            = "ALERT",
    "@version"         = "alertapi-0.1"
  })
  mime_type = "application/json"
}
