provider "azurerm" {
  features {}
}

data "azurerm_management_group" "baringsroot" {
  display_name = "ankur management group"
}

data "azurerm_user_assigned_identity" "mi-cloudops-azpolicy" {
  name                = "MyIdentity"
  resource_group_name = "sample-1"
}

resource "azurerm_policy_definition" "storage_diaglogs" {
  name         = "diag-logs-activity-sub"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "enable diagnostic setting for activity logs"

  metadata = <<METADATA
    {
    "category": "General"
    }
METADATA

  parameters = <<PARAMETERS
{
        "eventHubRuleId": {
            "type": "String",
            "metadata": {
                "displayName": "Event Hub Authorization Rule Id",
                "description": "The Event Hub authorization rule Id for Azure Diagnostics. The authorization rule needs to be at Event Hub namespace level. e.g. /subscriptions/{subscription Id}/resourceGroups/{resource group}/providers/Microsoft.EventHub/namespaces/{Event Hub namespace}/authorizationrules/{authorization rule}",
                "strongType": "Microsoft.EventHub/Namespaces/AuthorizationRules",
                "assignPermissions": true
            }
        },
        "effect": {
            "type": "String",
            "metadata": {
                "displayName": "Effects",
                "description": "Enable or disable the execution of the Policy."
            },
            "allowedValues": [
                "DeployIfNotExists",
                "Disabled"
            ],
            "defaultValue": "DeployIfNotExists"
        },
        "profileName": {
            "type": "String",
            "metadata": {
                "displayName": "Profile name",
                "description": "The diagnostic settings profile name"
            },
            "defaultValue": "setbypolicy_eventHub"
        }
    }
PARAMETERS


  policy_rule = <<POLICY_RULE

{
        "if": {
            "allOf": [
                {
                    "field": "type",
                    "equals": "Microsoft.Resources/subscriptions"
                }
            ]
        },
        "then": {
            "effect": "[parameters('effect')]",
            "details": {
                "type": "Microsoft.Insights/diagnosticSettings",
                "ExistenceScope": "Subscription",
                "DeploymentScope": "Subscription",
                "ExistenceCondition": {
                    "allOf": [
                        {
                            "field": "Microsoft.Insights/diagnosticSettings/eventHubAuthorizationRuleId",
                            "equals": "[parameters('eventHubRuleId')]"
                        },
                        {
                            "field": "name",
                            "equals": "[parameters('profileName')]"
                        }
                    ]
                },
                "roleDefinitionIds": [
                    "/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"
                ],
                "deployment": {
                    "location": "eastus",
                    "properties": {
                        "mode": "incremental",
                        "template": {
                            "$schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
                            "contentVersion": "1.0.0.0",
                            "parameters": {
                                "eventHubRuleId": {
                                    "type": "String"
                                },
                                "profileName": {
                                    "type": "String"
                                }
                            },
                            "variables": {},
                            "resources": [
                                {
                                    "type": "Microsoft.Insights/diagnosticSettings",
                                    "apiVersion": "2017-05-01-preview",
                                    "name": "[parameters('profileName')]",
                                    "location": "global",
                                    "properties": {
                                        "eventHubAuthorizationRuleId": "[parameters('eventHubRuleId')]",
                                        "logs": [
                                            {
                                                "category": "Administrative",
                                                "enabled": true
                                            },
                                            {
                                                "category": "Security",
                                                "enabled": true
                                            },
                                            {
                                                "category": "ServiceHealth",
                                                "enabled": true
                                            },
                                            {
                                                "category": "Alert",
                                                "enabled": true
                                            },
                                            {
                                                "category": "Recommendation",
                                                "enabled": true
                                            },
                                            {
                                                "category": "Policy",
                                                "enabled": true
                                            },
                                            {
                                                "category": "Autoscale",
                                                "enabled": true
                                            },
                                            {
                                                "category": "ResourceHealth",
                                                "enabled": true
                                            }
                                        ]
                                    }
                                }
                            ]
                        },
                        "parameters": {
                            "eventHubRuleId": {
                                "value": "[parameters('eventHubRuleId')]"
                            },
                            "profileName": {
                                "value": "[parameters('profileName')]"
                            }
                        }
                    }
                }
            }
        }
    }
POLICY_RULE

}


data "azurerm_subscription" "current" {}

resource "azurerm_subscription_policy_assignment" "assign_policy" {
  name                 = "policy-assignment-activity-logs"
  policy_definition_id = azurerm_policy_definition.storage_diaglogs.id
  subscription_id      = data.azurerm_subscription.current.id
  location             = "eastus"

  parameters = <<PARAMETERS
{
	"eventHubRuleId": {
		"value": "/subscriptions/f3d20c9f-3cb5-45df-b6a8-32f7f4e3d1b6/resourceGroups/sample-1/providers/Microsoft.EventHub/namespaces/eventnamespaceankur/authorizationRules/RootManageSharedAccessKey"
	},
	"profileName": {
		"value": "setbypolicy_eventHub"
	}
}
  PARAMETERS

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.mi-cloudops-azpolicy.id]

  }

}
