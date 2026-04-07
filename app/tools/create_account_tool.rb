class CreateAccountTool < ApplicationTool
  SIMPLE_TYPES = %w[Depository Investment Crypto OtherAsset OtherLiability].freeze

  description "Create a new financial account (checking, savings, investment, crypto, etc). For loans use create_loan_account. For credit cards use create_credit_card_account."

  arguments do
    required(:name).filled(:string).description("Account name e.g. 'Chase Checking'")
    required(:accountable_type).filled(:string).description("One of: Depository, Investment, Crypto, OtherAsset, OtherLiability")
    required(:balance).filled(:float).description("Current balance")
    optional(:currency).filled(:string).description("ISO currency code, defaults to family currency")
    optional(:subtype).filled(:string).description("Account subtype e.g. 'checking', 'savings', '401k'")
  end

  def call(name:, accountable_type:, balance:, currency: nil, subtype: nil)
    require_write_access!
    unless SIMPLE_TYPES.include?(accountable_type)
      return { success: false, errors: ["accountable_type must be one of: #{SIMPLE_TYPES.join(', ')}"] }
    end

    currency ||= current_family.currency
    accountable_attrs = subtype.present? ? { account_type: subtype } : {}

    account = Account.create_and_sync(
      name: name,
      currency: currency,
      balance: balance,
      family: current_family,
      accountable_type: accountable_type,
      accountable_attributes: accountable_attrs
    )

    { success: true, id: account.id, name: account.name, type: account.accountable_type, balance: account.balance }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end
end
