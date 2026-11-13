variable "image_uri" {
  type        = string
  description = "Immutable ECR image reference, preferably repository@sha256:digest."
}
variable "execution_role_arn" {
  type        = string
  default     = ""
  description = "Existing ECS task execution role (e.g. LabRole); empty creates a scoped role."
}
variable "desired_count" {
  type    = number
  default = 1
  validation {
    condition     = var.desired_count >= 1 && var.desired_count <= 4 && floor(var.desired_count) == var.desired_count
    error_message = "desired_count must be an integer from 1 to 4."
  }
}
