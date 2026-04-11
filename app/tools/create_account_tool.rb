class CreateAccountTool < ApplicationTool
  SIMPLE_TYPES        = %w[Depository Investment Crypto OtherAsset OtherLiability].freeze
  DEPOSITORY_SUBTYPES = Depository::SUBTYPES.keys.freeze
  INVESTMENT_SUBTYPES = Investment::SUBTYPES.keys.freeze

  description "Create a new financial account (checking, savings, investment, crypto, etc). " \
              "For loans use create_loan_account. For credit cards use create_credit_card_account."

  input_schema(
    properties: {
      name: { type: "string", description: "Account name e.g. 'Chase Checking'" },
      accountable_type: { type: "string", description: "One of: Depository, Investment, Crypto, OtherAsset, OtherLiability" },
      balance: { type: "string", description: "Current balance as a number e.g. '5000' or '5000.50'" },
      currency: { type: "string", description: "ISO currency code, defaults to family currency" },
      subtype: { type: "string", description: "Account subtype. Depository: #{DEPOSITORY_SUBTYPES.join(', ')}. Investment: #{INVESTMENT_SUBTYPES.join(', ')}." }
    },
    required: %w[name accountable_type balance]
  )

  class << self
    def call(server_context:, name:, accountable_type:, balance:, currency: nil, subtype: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)

      unless SIMPLE_TYPES.include?(accountable_type)
        return text_response({ success: false, errors: [ "accountable_type must be one of: #{SIMPLE_TYPES.join(', ')}" ] })
      end

      currency ||= family.currency

      account = Account.create_and_sync(
        name: name,
        currency: currency,
        balance: balance.to_f,
        subtype: subtype,
        family: family,
        accountable_type: accountable_type
      )

      text_response({ success: true, id: account.id, name: account.name, type: account.accountable_type, balance: account.balance })
    rescue ActiveRecord::RecordInvalid => e
      text_response({ success: false, errors: e.record.errors.full_messages })
    end
  end
end
