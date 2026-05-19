variable "postgresql_admin_user" {
  description = "PostgreSQL admin username"
  type        = string
  sensitive   = true
}

variable "postgresql_admin_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "jwt_encryption_key" {
  description = "JWT encryption key"
  type        = string
  sensitive   = true
}

variable "jwt_auth_key" {
  description = "JWT auth key"
  type        = string
  sensitive   = true
}

variable "jwt_key" {
  description = "JWT key for frontend"
  type        = string
  sensitive   = true
}

variable "stripe_secret_key" {
  description = "Stripe secret key"
  type        = string
  sensitive   = true
  default     = "placeholder"
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  sensitive   = true
  default     = "placeholder"
}

variable "google_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
  default     = "placeholder"
}
