class CreateTransferTool < ApplicationTool
  description "Create a transfer between two accounts. Auto-classifies based on destination: " \
              "credit-card payment (destination is a credit card), " \
              "loan/EMI payment (destination is a loan), or " \
              "regular funds movement (e.g. savings -> checking, lending). " \
              "IMPORTANT: Always confirm details with the user before calling. " \
              "Required: from_account_id, to_account_id, amount, date (YYYY-MM-DD). " \
              "Date must be within 4 days of today. Accounts must differ."

  input_schema(
    properties: {
      from_account_id: { type: "string", description: "Source account UUID (money leaves here)" },
      to_account_id:   { type: "string", description: "Destination account UUID (money arrives here). Must differ from source. If a liability or loan, this is treated as a payment." },
      amount:          { type: "string", description: "Positive amount in source account currency, e.g. '500.00'" },
      date:            { type: "string", description: "YYYY-MM-DD. Must be within 4 days of today." }
    },
    required: %w[from_account_id to_account_id amount date]
  )

  class << self
    def call(server_context:, from_account_id:, to_account_id:, amount:, date:, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)

      transfer = Transfer::Creator.new(
        family: family,
        source_account_id: from_account_id,
        destination_account_id: to_account_id,
        date: Date.parse(date),
        amount: amount.to_d
      ).create

      if transfer.persisted?
        text_response({
          success: true,
          id: transfer.id,
          transfer_type: transfer.transfer_type,
          from_account: transfer.from_account.name,
          to_account: transfer.to_account.name,
          amount: transfer.amount_abs.amount.to_f,
          currency: transfer.amount_abs.currency.iso_code,
          date: transfer.date.iso8601
        })
      else
        text_response({ success: false, errors: transfer.errors.full_messages })
      end
    end
  end
end
