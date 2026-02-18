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

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for instance access"
}

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR block allowed for SSH access"
}

variable "instance_name" {
  type        = string
  default     = "openclaw-server"
  description = "Name for the Compute Engine instance"
}
