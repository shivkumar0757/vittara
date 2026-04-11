class WellKnownController < ApplicationController
  skip_authentication

  # RFC 8414 — OAuth 2.0 Authorization Server Metadata
  def oauth_authorization_server
    render json: {
      issuer: root_url,
      authorization_endpoint: oauth_authorization_url,
      token_endpoint: oauth_token_url,
      revocation_endpoint: oauth_revoke_url,
      introspection_endpoint: oauth_introspect_url,
      scopes_supported: %w[read read_write],
      response_types_supported: %w[code],
      grant_types_supported: %w[authorization_code],
      code_challenge_methods_supported: %w[S256],
      token_endpoint_auth_methods_supported: %w[client_secret_post client_secret_basic]
    }
  end

  # RFC 9728 — OAuth 2.0 Protected Resource Metadata
  def oauth_protected_resource
    render json: {
      resource: request.base_url,
      authorization_servers: [ root_url ],
      scopes_supported: %w[read read_write]
    }
  end
end
