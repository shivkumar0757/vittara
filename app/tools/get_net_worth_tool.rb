class GetNetWorthTool < ApplicationTool
  description "Get current net worth, total assets, and total liabilities"
  arguments { }

  def call
    sheet = BalanceSheet.new(current_family)
    {
      net_worth: sheet.net_worth_money.format,
      assets: sheet.assets.total_money.format,
      liabilities: sheet.liabilities.total_money.format,
      currency: current_family.currency
    }
  end
end
