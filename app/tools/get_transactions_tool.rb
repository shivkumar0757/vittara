class GetTransactionsTool < ApplicationTool
  description "List transactions with optional filters by account, date range, or limit"

  input_schema(
    properties: {
      account_id: { type: "string", description: "Filter by account ID" },
      start_date: { type: "string", description: "Start date (YYYY-MM-DD)" },
      end_date: { type: "string", description: "End date (YYYY-MM-DD)" },
      limit: { type: "integer", description: "Max results (default 20, max 100)" }
    }
  )

  class << self
    def call(server_context:, account_id: nil, start_date: nil, end_date: nil, limit: 20, **_params)
      family = current_family(server_context)
      limit = [ [ limit.to_i, 1 ].max, 100 ].min
      entries = family.entries.visible.preload(:account, :entryable)
      entries = entries.where(account_id: account_id) if account_id
      entries = entries.where("date >= ?", Date.parse(start_date)) if start_date
      entries = entries.where("date <= ?", Date.parse(end_date)) if end_date
      transactions = entries.order(date: :desc).limit(limit).map do |entry|
        {
          id: entry.id,
          date: entry.date.iso8601,
          name: entry.name,
          amount: entry.amount,
          currency: entry.currency,
          category: entry.transaction&.category&.name,
          account: entry.account.name
        }
      end
      text_response(transactions)
    end
  end
end
