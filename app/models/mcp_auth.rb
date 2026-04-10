class McpAuth
  attr_reader :user, :scopes, :source

  def self.resolve(token)
    return nil unless token

    # Try ApiKey first (Claude Desktop / Cursor flow)
    if (api_key = ApiKey.find_by_value(token)) && api_key.active? && api_key.source == "mcp"
      new(
        user: api_key.user,
        scopes: api_key.scopes,
        source: :api_key,
        record: api_key
      )
    # Try Doorkeeper OAuth (Claude Custom Connector flow)
    elsif (access_token = Doorkeeper::AccessToken.by_token(token))
      return nil if access_token.revoked? || access_token.expired?
      user = User.find_by(id: access_token.resource_owner_id)
      return nil unless user

      new(
        user: user,
        scopes: access_token.scopes.to_a,
        source: :oauth,
        record: access_token
      )
    end
  end

  def initialize(user:, scopes:, source:, record:)
    @user = user
    @scopes = scopes
    @source = source
    @record = record
  end

  def write?
    scopes.include?("read_write")
  end

  def touch_last_used!
    case source
    when :api_key
      @record.update_last_used!
    end
  end
end
