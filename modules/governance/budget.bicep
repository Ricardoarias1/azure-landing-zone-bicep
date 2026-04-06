metadata description = 'Creates a subscription-level cost budget with email alert notifications'

targetScope = 'subscription'

@description('Budget name')
param budgetName string

@description('Monthly budget amount in USD')
param amount int

@description('Budget start date (YYYY-MM-01 format)')
param startDate string

@description('Budget end date (YYYY-MM-01 format)')
param endDate string

@description('Email addresses to notify when thresholds are crossed')
param contactEmails array

@description('Alert at this % of budget (first threshold)')
@minValue(1)
@maxValue(100)
param alertThreshold int = 80

@description('Alert at this % of budget (second threshold — forecasted)')
@minValue(1)
@maxValue(100)
param alertThresholdForecast int = 100

resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications: {
      actualAlert: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThreshold
        thresholdType: 'Actual'
        contactEmails: contactEmails
      }
      forecastAlert: {
        enabled: true
        operator: 'GreaterThan'
        threshold: alertThresholdForecast
        thresholdType: 'Forecasted'
        contactEmails: contactEmails
      }
    }
  }
}

output budgetId string = budget.id
output budgetName string = budget.name
