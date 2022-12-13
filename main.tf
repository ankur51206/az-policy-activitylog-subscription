provider "azurerm" {
  features {}
}

data "azurerm_management_group" "mysetexp" {
  display_name = "ankur management group"
}

data "azurerm_user_assigned_identity" "mycloudazpolicy" {
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
	"logAnalytics": {
		"type": "string",
		"metadata": {
			"displayName": "Log Analytics workspace",
			"description": "Select the Log Analytics workspace from dropdown list",
			"strongType": "omsWorkspace"
		}
	},
	"location": {
		"type": "string",
		"metadata": {
			"displayName": "location",
			"description": "Select location where the resources is deployed",
			"strongType": "location"
		}
	},
	"eventHub": {
		"type": "string",
		"metadata": {
			"displayName": "eventHub",
			"description": "Event hub where logs will be sent",
			"strongType": "Microsoft.EventHub/namespaces/eventhubs"
		}
	},
	"authorizationRule": {
		"type": "string",
		"metadata": {
			"displayName": "authorizationRule",
			"description": "Select the access key for the eventhub",
			"strongType": "Microsoft.EventHub/namespaces/AuthorizationRules"
		}
	}
}
PARAMETERS


  policy_rule = <<POLICY_RULE

{
	"if": {
		"allOf": [{
				"field": "type",
				"equals": "Microsoft.Subscription/"
			},
			{
				"field": "location",
				"equals": "[parameters('location')]"
			}
		]
	},
	"then": {
		"effect": "deployIfNotExists",
		"details": {
			"type": "Microsoft.Insights/diagnosticSettings",
			"roleDefinitionIds": [
				"/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
			],
			"existenceCondition": {
				"allOf": [{
						"field": "Microsoft.Insights/diagnosticSettings/logs.enabled",
						"equals": "True"
					},
					{
						"field": "Microsoft.Insights/diagnosticSettings/metrics.enabled",
						"equals": "True"
					},
					{
						"field": "Microsoft.Insights/diagnosticSettings/workspaceId",
						"matchInsensitively": "[parameters('logAnalytics')]"
					},
					{
						"field": "Microsoft.Insights/diagnosticSettings/eventHubAuthorizationRuleId",
						"matchInsensitively": "[parameters('authorizationRule')]"
					},
					{
						"field": "Microsoft.Insights/diagnosticSettings/eventHubName",
						"matchInsensitively": "[parameters('eventHub')]"
					}
				]
			},
			"deployment": {
				"properties": {
					"mode": "incremental",
					"template": {
						"$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
						"contentVersion": "1.0.0.0",
						"parameters": {
							"resourceName": {
								"type": "string"
							},
							"logAnalytics": {
								"type": "string"
							},
							"location": {
								"type": "string"
							},
							"authorizationRule": {
								"type": "string"
							},
							"eventHub": {
								"type": "string"
							}
						},
						"variables": {},
						"resources": [{
							"type": "Microsoft.Insights/diagnosticSettings",
							"apiVersion": "2017-05-01-preview",
							"name": "SubscriptionEventHubDiags-setByPolicy",
							"location": "[parameters('location')]",
							"properties": {
								"workspaceId": "[parameters('workspaceId')]",
								"eventHubAuthorizationRuleId": "[parameters('authorizationRule')]",
								"eventHubName": "[parameters('eventHub')]",
								"logs": [{
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
						}],
						"outputs": {}
					},
					"parameters": {
						"logAnalytics": {
							"value": "[parameters('logAnalytics')]"
						},
						"location": {
							"value": "[field('location')]"
						},
						"resourceName": {
							"value": "[field('name')]"
						},
						"authorizationRule": {
							"value": "[parameters('authorizationRule')]"
						},
						"eventHub": {
							"value": "[parameters('eventHub')]"
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
  name                 = "policy-assignment-activity-laws1"
  policy_definition_id = azurerm_policy_definition.storage_diaglogs.id
  subscription_id      = data.azurerm_subscription.current.id
  location             = "eastus"

  parameters = <<PARAMETERS
      {
	"authorizationRule": {
		"value": "/subscriptions/f3d20c9f-3cb5-45df-b6a8-32f7f4e3d1b6/resourceGroups/sample-1/providers/Microsoft.EventHub/namespaces/eventnamespaceankur/authorizationRules/RootManageSharedAccessKey"
	},
	"eventHub": {
		"value": "activitylogssub"
	},
	"logAnalytics": {
		"value": "/subscriptions/f3d20c9f-3cb5-45df-b6a8-32f7f4e3d1b6/resourcegroups/sample-1/providers/microsoft.operationalinsights/workspaces/samplelaws"
	},
	"Location": {
		"value": "eastus"
	}
}
  PARAMETERS

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.mycloudazpolicy.id]

  }

}
