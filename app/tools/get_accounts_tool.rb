class GetAccountsTool < ApplicationTool
  description "List all visible accounts with name, type, subtype, balance, currency, classification (asset/liability)"
  input_schema(properties: {})

  class << self
    def call(server_context:, **_params)
      family = current_family(server_context)
      accounts = family.accounts.visible.alphabetically.map do |account|
        {
          id: account.id,
          name: account.name,
          type: account.accountable_type,
          subtype: account.accountable.try(:account_type),
          balance: account.balance,
          currency: account.currency,
          classification: account.classification
        }
      end
      text_response(accounts)
    end
  end
end
