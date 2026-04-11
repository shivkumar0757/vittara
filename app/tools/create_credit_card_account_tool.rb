class CreateCreditCardAccountTool < ApplicationTool
  description "Create a credit card account."

  input_schema(
    properties: {
      name: { type: "string", description: "Card name e.g. 'Chase Sapphire'" },
      balance: { type: "string", description: "Current outstanding balance (amount owed) e.g. '2500' or '2500.00'" },
      currency: { type: "string", description: "ISO currency code, defaults to family currency" },
      available_credit: { type: "string", description: "Available credit remaining e.g. '7500'" },
      apr: { type: "string", description: "Annual percentage rate e.g. '24.99'" },
      minimum_payment: { type: "string", description: "Minimum monthly payment e.g. '35'" }
    },
    required: %w[name balance]
  )

  class << self
    def call(server_context:, name:, balance:, currency: nil, available_credit: nil, apr: nil, minimum_payment: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)

      balance          = balance.to_f
      available_credit = available_credit&.to_f
      apr              = apr&.to_f
      minimum_payment  = minimum_payment&.to_f
      currency ||= family.currency

      account = Account.create_and_sync(
        name: name,
        currency: currency,
        balance: balance,
        family: family,
        accountable_type: "CreditCard",
        accountable_attributes: {
          available_credit: available_credit,
          apr: apr,
          minimum_payment: minimum_payment
        }.compact
      )

      text_response({ success: true, id: account.id, name: account.name, balance: account.balance })
    rescue ActiveRecord::RecordInvalid => e
      text_response({ success: false, errors: e.record.errors.full_messages })
    end
  end
end
