output "instance_id" {
  description = "Compute Engine instance ID"
  value       = google_compute_instance.server.instance_id
}

output "public_ip" {
  description = "Public IP address"
  value       = google_compute_instance.server.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh ubuntu@${google_compute_instance.server.network_interface[0].access_config[0].nat_ip}"
}
