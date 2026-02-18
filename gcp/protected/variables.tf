variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "GCP region"
}

variable "zone" {
  type        = string
  default     = "us-central1-a"
  description = "GCP zone"
}

variable "machine_type" {
  type        = string
  default     = "e2-medium"
  description = "Compute Engine machine type"
}

variable "disk_size" {
  type        = number
  default     = 20
  description = "Boot disk size in GB"
}

variable "instance_name" {
  type        = string
  default     = "openclaw-server"
  description = "Name for the Compute Engine instance"
}

variable "enable_tailscale_direct" {
  type        = bool
  default     = false
  description = "Enable inbound UDP 41641 for direct Tailscale peer-to-peer connections"
}
