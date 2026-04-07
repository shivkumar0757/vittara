class GetTransactionsTool < ApplicationTool
  description "List transactions with optional filters by account, date range, or limit"

  arguments do
    optional(:account_id).filled(:integer)
    optional(:start_date).filled(:string)
    optional(:end_date).filled(:string)
    optional(:limit).filled(:integer)
  end

  def call(account_id: nil, start_date: nil, end_date: nil, limit: 20)
    limit = [[limit.to_i, 1].max, 100].min
    entries = current_family.entries.visible.preload(:account, :entryable)
    entries = entries.where(account_id: account_id) if account_id
    entries = entries.where("date >= ?", Date.parse(start_date)) if start_date
    entries = entries.where("date <= ?", Date.parse(end_date)) if end_date
    entries.order(date: :desc).limit(limit).map do |entry|
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
  end
end
