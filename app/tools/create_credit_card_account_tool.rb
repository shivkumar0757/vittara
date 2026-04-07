class CreateCreditCardAccountTool < ApplicationTool
  description "Create a credit card account."

  arguments do
    required(:name).filled(:string).description("Card name e.g. 'Chase Sapphire'")
    required(:balance).filled(:float).description("Current outstanding balance (amount owed)")
    optional(:currency).filled(:string).description("ISO currency code, defaults to family currency")
    optional(:available_credit).filled(:float).description("Available credit remaining")
    optional(:apr).filled(:float).description("Annual percentage rate e.g. 24.99")
    optional(:minimum_payment).filled(:float).description("Minimum monthly payment")
  end

  def call(name:, balance:, currency: nil, available_credit: nil, apr: nil, minimum_payment: nil)
    require_write_access!
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
