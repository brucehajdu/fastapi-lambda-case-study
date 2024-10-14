variable "name" {
  description = "The name of the repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Whether or not to scan images on push"
  type        = bool
  default     = false
}

variable "encryption_type" {
  description = "The encryption type for the repository"
  type        = string
  default     = "AES256"
}

variable "lifecycle_policy" {
  description = "The lifecycle policy for the repository"
  type        = map(any)
  default = {
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  }
}
