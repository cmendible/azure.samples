param subscription_id string
param actiongroup_id string
param activity_log_alert_name string = 'cfm test'
param alert_rule_name string = 'Exclude VMs from Resource Group when description contains YADA YADA'
param resource_group_name string

resource activity_log_alert_resource 'microsoft.insights/activityLogAlerts@2020-10-01' = {
  name: activity_log_alert_name
  location: 'Global'
  properties: {
    scopes: [
      '/subscriptions/${subscription_id}'
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
        {
          anyOf: [
            {
              field: 'properties.incidentType'
              equals: 'Incident'
            }
          ]
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actiongroup_id
          webhookProperties: {
          }
        }
      ]
    }
    enabled: true
  }
}

resource alert_rule_resource 'Microsoft.AlertsManagement/actionRules@2021-08-08' = {
  name: alert_rule_name
  location: 'Global'
  properties: {
    scopes: [
      '/subscriptions/${subscription_id}'
    ]
    conditions: [
      {
        field: 'TargetResourceGroup'
        operator: 'Equals'
        values: [
          '/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}'
        ]
      }
      {
        field: 'Description'
        operator: 'Contains'
        values: [
          'YADA YADA'
        ]
      }
      {
        field: 'TargetResourceType'
        operator: 'Equals'
        values: [
          'microsoft.compute/virtualmachines'
        ]
      }
    ]
    enabled: true
    actions: [
      {
        actionType: 'RemoveAllActionGroups'
      }
    ]
  }
}
