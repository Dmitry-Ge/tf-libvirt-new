variable "ssh-public-key" {
  description = "SSH public key"
  type        = string
  default     = ""
}

variable "password" {
  description = "Password"
  type        = string
  default     = ""
}

variable "servers" {
  description = "Список серверов"
  type = map(object({
    name = string
    cpu  = number
    ram  = number
  }))

  default = {
    "srv1" = {
      name = "web-01"
      cpu  = 2
      ram  = 2048
    },
    "srv2" = {
      name = "db-01"
      cpu  = 4
      ram  = 2048
    }
  }
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 4
}
