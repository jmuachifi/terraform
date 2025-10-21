# TFLint configuration for Terraform (Azure-focused)

config {
  # TFLint v0.54+: use call_module_type instead of deprecated `module`
  # Options: "none", "local", "remote", "all"
  call_module_type = "all"
}

# Tip: To enable the AzureRM ruleset, install the plugin and uncomment below.
# This requires internet access to download the plugin.
#
# plugin "azurerm" {
#   enabled = true
#   version = "~> 0.27.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
# }
plugin "terraform" {
  enabled          = true
  call_module_type = "all"
}

plugin "azurerm" {
  enabled = true
  version = "0.26.0"  # latest plugin
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}


# Example to enable/disable specific core rules:
# rule "terraform_workspace_remote" { enabled = true }