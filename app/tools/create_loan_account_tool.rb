class CreateLoanAccountTool < ApplicationTool
  LOAN_SUBTYPES = Loan::SUBTYPES.keys.freeze

  description "Create a loan account (mortgage, auto loan, personal loan, student loan, etc). " \
              "Subtypes: #{LOAN_SUBTYPES.join(', ')}."

  arguments do
    required(:name).filled(:string).description("Loan name e.g. 'Home Mortgage'")
    required(:balance).filled(:string).description("Current outstanding balance e.g. '300000' or '300000.00'")
    optional(:currency).filled(:string).description("ISO currency code, defaults to family currency")
    optional(:subtype).filled(:string).description("Loan subtype: #{LOAN_SUBTYPES.join(', ')}")
    optional(:interest_rate).filled(:string).description("Annual interest rate as percentage e.g. '6.5'")
    optional(:term_months).filled(:integer).description("Loan term in months e.g. 360 for 30-year")
    optional(:initial_balance).filled(:string).description("Original loan amount — defaults to current balance e.g. '350000'")
    optional(:rate_type).filled(:string).description("'fixed' or 'variable'")
  end

  def call(name:, balance:, currency: nil, subtype: nil, interest_rate: nil, term_months: nil, initial_balance: nil, rate_type: nil)
    require_write_access!
    balance         = balance.to_f
    interest_rate   = interest_rate&.to_f
    initial_balance = initial_balance&.to_f
    currency ||= current_family.currency

    account = Account.create_and_sync(
      name: name,
      currency: currency,
      balance: balance,
      subtype: subtype,
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
