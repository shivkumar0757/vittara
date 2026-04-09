class CreateCreditCardAccountTool < ApplicationTool
  description "Create a credit card account."

  arguments do
    required(:name).filled(:string).description("Card name e.g. 'Chase Sapphire'")
    required(:balance).filled(:string).description("Current outstanding balance (amount owed) e.g. '2500' or '2500.00'")
    optional(:currency).filled(:string).description("ISO currency code, defaults to family currency")
    optional(:available_credit).filled(:string).description("Available credit remaining e.g. '7500'")
    optional(:apr).filled(:string).description("Annual percentage rate e.g. '24.99'")
    optional(:minimum_payment).filled(:string).description("Minimum monthly payment e.g. '35'")
  end

  def call(name:, balance:, currency: nil, available_credit: nil, apr: nil, minimum_payment: nil)
    require_write_access!
    balance          = balance.to_f
    available_credit = available_credit&.to_f
    apr              = apr&.to_f
    minimum_payment  = minimum_payment&.to_f
    currency ||= current_family.currency

    account = Account.create_and_sync(
      name: name,
      currency: currency,
      balance: balance,
      family: current_family,
      accountable_type: "CreditCard",
      accountable_attributes: {
        available_credit: available_credit,
        apr: apr,
        minimum_payment: minimum_payment
      }.compact
    )

    { success: true, id: account.id, name: account.name, balance: account.balance }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end
end
