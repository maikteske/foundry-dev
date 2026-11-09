variable "account_id" {
  description = "Ressourcen-ID des bestehenden Foundry-Accounts (Microsoft.CognitiveServices/accounts)"
  type        = string
}

variable "deployments" {
  description = "Zu erstellende Model-Deployments. Key = Deployment-Name in der API; modelName/version = zugrundeliegendes Modell"
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = string
    capacity      = number
  }))
}

variable "rai_policy_name" {
  description = "Content-Filter-Policy der Deployments (live: Microsoft.DefaultV2)"
  type        = string
  default     = "Microsoft.DefaultV2"
}

variable "version_upgrade_option" {
  description = "Verhalten bei neuen Modellversionen: OnceNewDefaultVersionAvailable = automatisches Upgrade"
  type        = string
  default     = "OnceNewDefaultVersionAvailable"

  validation {
    condition = contains(
      ["OnceCurrentVersionExpired", "OnceNewDefaultVersionAvailable"],
      var.version_upgrade_option
    )
    error_message = "Nur OnceCurrentVersionExpired oder OnceNewDefaultVersionAvailable."
  }
}
