variable "principal_id" {
  description = "Principal-ID der APIM-System-MI"
  type        = string
}

variable "account_id" {
  description = "Ressourcen-ID des bestehenden Foundry-Accounts (Assignment-Scope)"
  type        = string
}

variable "role_assignment_name" {
  description = "Fixe Assignment-GUID (Bicep: guid(account.id, 'apim-openai-user'))"
  type        = string
}

variable "role_definition_id" {
  description = "Vollständige Role-Definition-ID (Cognitive Services OpenAI User)"
  type        = string
}
