variable "url" {
  type        = string
  description = "The URL of the OIDC identity provider"
}

variable "client_id_list" {
  type        = list(string)
  description = "List of client IDs for the OIDC identity provider"
}

variable "thumbprint_list" {
  type        = list(string)
  description = "List of thumbprints for the OIDC identity provider"
}
