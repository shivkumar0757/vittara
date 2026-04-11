class GetNetWorthTool < ApplicationTool
  description "Get current net worth, total assets, and total liabilities"
  input_schema(properties: {})

  class << self
    def call(server_context:, **_params)
      family = current_family(server_context)
      sheet = BalanceSheet.new(family)
      text_response({
        net_worth: sheet.net_worth_money.format,
        assets: sheet.assets.total_money.format,
        liabilities: sheet.liabilities.total_money.format,
        currency: family.currency
      })
    end
  end
end
