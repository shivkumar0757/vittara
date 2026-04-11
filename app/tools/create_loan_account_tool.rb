class CreateLoanAccountTool < ApplicationTool
  LOAN_SUBTYPES = Loan::SUBTYPES.keys.freeze

  description "Create a loan account (mortgage, auto loan, personal loan, student loan, etc). " \
              "Subtypes: #{LOAN_SUBTYPES.join(', ')}."

  input_schema(
    properties: {
      name: { type: "string", description: "Loan name e.g. 'Home Mortgage'" },
      balance: { type: "string", description: "Current outstanding balance e.g. '300000' or '300000.00'" },
      currency: { type: "string", description: "ISO currency code, defaults to family currency" },
      subtype: { type: "string", description: "Loan subtype: #{LOAN_SUBTYPES.join(', ')}" },
      interest_rate: { type: "string", description: "Annual interest rate as percentage e.g. '6.5'" },
      term_months: { type: "integer", description: "Loan term in months e.g. 360 for 30-year" },
      initial_balance: { type: "string", description: "Original loan amount — defaults to current balance e.g. '350000'" },
      rate_type: { type: "string", description: "'fixed' or 'variable'" }
    },
    required: %w[name balance]
  )

  class << self
    def call(server_context:, name:, balance:, currency: nil, subtype: nil, interest_rate: nil, term_months: nil, initial_balance: nil, rate_type: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)

      balance         = balance.to_f
      interest_rate   = interest_rate&.to_f
      initial_balance = initial_balance&.to_f
      currency ||= family.currency

      account = Account.create_and_sync(
        name: name,
        currency: currency,
        balance: balance,
        subtype: subtype,
        family: family,
        accountable_type: "Loan",
        accountable_attributes: {
          rate_type: rate_type,
          interest_rate: interest_rate,
          term_months: term_months,
          initial_balance: initial_balance || balance
        }.compact
      )

      text_response({ success: true, id: account.id, name: account.name, balance: account.balance })
    rescue ActiveRecord::RecordInvalid => e
      text_response({ success: false, errors: e.record.errors.full_messages })
    end
  end
end
