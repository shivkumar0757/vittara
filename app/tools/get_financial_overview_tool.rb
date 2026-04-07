class GetFinancialOverviewTool < ApplicationTool
  description "Get a financial snapshot: net worth, total assets/liabilities, and this month's income and expenses"

  arguments { }

  def call
    sheet = BalanceSheet.new(current_family)
    totals = current_family.income_statement.totals(
      transactions_scope: current_family.transactions.visible.in_period(Period.current_month)
    )

    {
      net_worth: sheet.net_worth_money.format,
      assets: sheet.assets.total_money.format,
      liabilities: sheet.liabilities.total_money.format,
      this_month_income: totals.income_money.format,
      this_month_expenses: totals.expense_money.format,
      currency: current_family.currency
    }
  end
end
