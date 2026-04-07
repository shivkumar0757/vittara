class CreateTransactionTool < ApplicationTool
  description "Create a new transaction. IMPORTANT: Always confirm details with the user before calling this tool. Required: account_id, amount, date (YYYY-MM-DD), name. Amount sign: positive = expense, negative = income. Or use nature: 'expense'/'income' to auto-sign."

  arguments do
    required(:account_id).filled(:string).description("Account ID (UUID) to log transaction against")
    required(:amount).filled(:string).description("Amount as a number string e.g. '45.00' — positive=expense, negative=income. Or use nature param.")
    required(:date).filled(:string).description("Date in YYYY-MM-DD format")
    required(:name).filled(:string).description("Transaction name/description")
    optional(:nature).filled(:string).description("'expense' or 'income' — overrides amount sign")
    optional(:category_id).filled(:string).description("Category ID (UUID)")
    optional(:notes).filled(:string)
    optional(:currency).filled(:string)
  end

  def call(account_id:, amount:, date:, name:, nature: nil, category_id: nil, notes: nil, currency: nil)
    require_write_access!
    account = current_family.accounts.find(account_id)
    signed_amount = calculate_signed_amount(amount.to_f, nature)
    currency ||= current_family.currency

    entry = account.entries.new(
      name: name,
      date: Date.parse(date),
      amount: signed_amount,
      currency: currency,
      notes: notes,
      entryable_type: "Transaction",
      entryable_attributes: { category_id: category_id }.compact
    )

    if entry.save
      entry.sync_account_later
      { success: true, id: entry.id, name: entry.name, amount: entry.amount, date: entry.date.iso8601 }
    else
      { success: false, errors: entry.errors.full_messages }
    end
  end

  private

    def calculate_signed_amount(amount, nature)
      case nature&.downcase
      when "income", "inflow" then -amount.abs
      when "expense", "outflow" then amount.abs
      else amount
      end
    end
end
