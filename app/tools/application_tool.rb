class ApplicationTool < FastMcp::Tool
  UnauthorizedError = Class.new(StandardError)

  authorize do |_arguments|
    authenticate_mcp_token!
  end

  private

    def authenticate_mcp_token!
      token = extract_bearer_token
      api_key = token ? ApiKey.find_by_value(token) : nil

      unless api_key&.active? && api_key.source == "mcp"
        raise UnauthorizedError, "Invalid or missing MCP token"
      end

      setup_current_context(api_key)
      api_key.update_last_used!
    end

    def extract_bearer_token
      # fast-mcp lowercases header keys: HTTP_AUTHORIZATION → "authorization"
      auth_header = headers["authorization"] || headers["AUTHORIZATION"]
      return nil unless auth_header&.start_with?("Bearer ")

      auth_header.split(" ", 2).last.presence
    end

    def setup_current_context(api_key)
      user = api_key.user
      session = user.sessions.first ||
        user.sessions.build(user_agent: "MCP Client", ip_address: "0.0.0.0")
      Current.session = session
    end

    def current_family
      Current.family
    end

    def require_write_access!
      api_key = find_current_api_key
      unless api_key&.scopes&.include?("read_write")
        raise UnauthorizedError, "Write access requires read_write scope"
      end
    end

    def find_current_api_key
      token = extract_bearer_token
      token ? ApiKey.find_by_value(token) : nil
    end
end
