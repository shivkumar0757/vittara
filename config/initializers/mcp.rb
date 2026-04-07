require "fast_mcp"

# fast-mcp reads Rails.application.config.hosts to build allowed_origins.
# In development/test with no hosts configured, this is nil — guard against it.
Rails.application.config.hosts ||= []

FastMcp.mount_in_rails(
  Rails.application,
  name: "vittara",
  version: "1.0.0",
  path_prefix: "/mcp",
  allowed_origins: []
) do |server|
  Rails.application.config.after_initialize do
    server.register_tools(
      GetFinancialOverviewTool,
      GetAccountsTool,
      GetNetWorthTool,
      GetTransactionsTool,
      GetCategoriesTool,
      CreateTransactionTool,
      UpdateTransactionTool,
      CreateAccountTool,
      CreateLoanAccountTool,
      CreateCreditCardAccountTool,
    )
  end
end
