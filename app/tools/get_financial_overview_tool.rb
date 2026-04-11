class GetFinancialOverviewTool < ApplicationTool
  description "Get a financial snapshot: net worth, total assets/liabilities, and this month's income and expenses"
  input_schema(properties: {})

  class << self
    def call(server_context:, **_params)
      family = current_family(server_context)
      sheet = BalanceSheet.new(family)
      totals = family.income_statement.totals(
        transactions_scope: family.transactions.visible.in_period(Period.current_month)
      )

      text_response({
        net_worth: sheet.net_worth_money.format,
        assets: sheet.assets.total_money.format,
        liabilities: sheet.liabilities.total_money.format,
        this_month_income: totals.income_money.format,
        this_month_expenses: totals.expense_money.format,
        currency: family.currency
      })
    end
  end
end
