class CreateLoanAccountTool < ApplicationTool
  description "Create a loan account (mortgage, auto loan, personal loan, student loan, etc)."

  arguments do
    required(:name).filled(:string).description("Loan name e.g. 'Home Mortgage'")
    required(:balance).filled(:float).description("Current outstanding balance")
    optional(:currency).filled(:string).description("ISO currency code, defaults to family currency")
    optional(:interest_rate).filled(:float).description("Annual interest rate as percentage e.g. 6.5")
    optional(:term_months).filled(:integer).description("Loan term in months e.g. 360 for 30-year")
    optional(:initial_balance).filled(:float).description("Original loan amount — defaults to current balance")
    optional(:rate_type).filled(:string).description("'fixed' or 'variable'")
  end

  def call(name:, balance:, currency: nil, interest_rate: nil, term_months: nil, initial_balance: nil, rate_type: nil)
    require_write_access!
    currency ||= current_family.currency

    account = Account.create_and_sync(
      name: name,
      currency: currency,
      balance: balance,
      family: current_family,
      accountable_type: "Loan",
      accountable_attributes: {
        rate_type: rate_type,
        interest_rate: interest_rate,
        term_months: term_months,
        initial_balance: initial_balance || balance
      }.compact
    )

    { success: true, id: account.id, name: account.name, balance: account.balance }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, errors: e.record.errors.full_messages }
  end
end
