output "instance_id" {
  description = "Compute Engine instance ID"
  value       = google_compute_instance.server.instance_id
}

output "iap_ssh_command" {
  description = "SSH command via IAP tunnel"
  value       = "gcloud compute ssh ${var.instance_name} --zone=${var.zone} --tunnel-through-iap"
}
