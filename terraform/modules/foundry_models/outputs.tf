output "deployment_ids" {
  description = "IDs der Deployment-Ressourcen"
  value       = { for name, d in azurerm_cognitive_deployment.this : name => d.id }
}
