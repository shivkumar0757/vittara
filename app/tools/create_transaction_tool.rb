class CreateTransactionTool < ApplicationTool
  description "Create a new transaction. IMPORTANT: Always confirm details with the user before calling this tool. Required: account_id, amount, date (YYYY-MM-DD), name. Amount sign: positive = expense, negative = income. Or use nature: 'expense'/'income' to auto-sign. Optional tag_ids attaches existing tags — call get_tags first to look up UUIDs (do NOT pass tag names)."

  input_schema(
    properties: {
      account_id: { type: "string", description: "Account ID (UUID) to log transaction against" },
      amount: { type: "string", description: "Amount as a number string e.g. '45.00' — positive=expense, negative=income. Or use nature param." },
      date: { type: "string", description: "Date in YYYY-MM-DD format" },
      name: { type: "string", description: "Transaction name/description" },
      nature: { type: "string", description: "'expense' or 'income' — overrides amount sign" },
      category_id: { type: "string", description: "Category ID (UUID)" },
      tag_ids: { type: "array", items: { type: "string" }, description: "Array of Tag UUIDs (NOT names). Use get_tags to find IDs, or create_tag first if a needed tag doesn't exist." },
      notes: { type: "string" },
      currency: { type: "string" }
    },
    required: %w[account_id amount date name]
  )

  class << self
    def call(server_context:, account_id:, amount:, date:, name:, nature: nil, category_id: nil, tag_ids: nil, notes: nil, currency: nil, **_params)
      require_write_access!(server_context)
      family = current_family(server_context)
      account = family.accounts.find(account_id)
      signed_amount = calculate_signed_amount(amount.to_f, nature)
      currency ||= family.currency

      entry = account.entries.new(
        name: name,
        date: Date.parse(date),
        amount: signed_amount,
        currency: currency,
        notes: notes,
        entryable_type: "Transaction",
        entryable_attributes: { category_id: category_id, tag_ids: tag_ids }.compact
      )

      if entry.save
        entry.sync_account_later
        text_response({ success: true, id: entry.id, name: entry.name, amount: entry.amount, date: entry.date.iso8601 })
      else
        text_response({ success: false, errors: entry.errors.full_messages })
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
end
