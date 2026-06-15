resource "azurerm_consumption_budget_subscription" "this" {
  name            = "${var.name_prefix}-monthly-budget"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.amount
  time_grain      = "Monthly"

  time_period {
    start_date = var.start_date
    end_date   = var.end_date
  }

  dynamic "notification" {
    for_each = var.notifications

    content {
      enabled        = true
      threshold      = notification.value.threshold
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_emails = notification.value.contact_emails
    }
  }
}
