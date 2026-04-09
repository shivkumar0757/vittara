class CreateAccountTool < ApplicationTool
  SIMPLE_TYPES        = %w[Depository Investment Crypto OtherAsset OtherLiability].freeze
  DEPOSITORY_SUBTYPES = Depository::SUBTYPES.keys.freeze
  INVESTMENT_SUBTYPES = Investment::SUBTYPES.keys.freeze

  description "Create a new financial account (checking, savings, investment, crypto, etc). " \
              "For loans use create_loan_account. For credit cards use create_credit_card_account."

  arguments do
    required(:name).filled(:string).description("Account name e.g. 'Chase Checking'")
    required(:accountable_type).filled(:string).description("One of: Depository, Investment, Crypto, OtherAsset, OtherLiability")
    required(:balance).filled(:string).description("Current balance as a number e.g. '5000' or '5000.50'")
    optional(:currency).filled(:string).description("ISO currency code, defaults to family currency")
    optional(:subtype).filled(:string).description(
      "Account subtype. Depository: #{DEPOSITORY_SUBTYPES.join(', ')}. Investment: #{INVESTMENT_SUBTYPES.join(', ')}."
    )
  end

  def call(name:, accountable_type:, balance:, currency: nil, subtype: nil)
    require_write_access!
    unless SIMPLE_TYPES.include?(accountable_type)
      return { success: false, errors: ["accountable_type must be one of: #{SIMPLE_TYPES.join(', ')}"] }
    end

    currency ||= current_family.currency

    account = Account.create_and_sync(
      name: name,
      currency: currency,
      balance: balance.to_f,
      subtype: subtype,
      family: current_family,
      accountable_type: accountable_type
    )

    { success: true, id: account.id, name: account.name, type: account.accountable_type, balance: account.balance }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end
end
