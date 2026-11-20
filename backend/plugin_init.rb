# frozen_string_literal: true

# Backend config defaults, applied for any key not set in config.rb.
# Frontend defaults are in frontend/lib/aspace_oauth.rb (CONFIG_DEFAULTS).
AppConfig[:oauth_allow_user_registration] = true unless AppConfig.has_key? :oauth_allow_user_registration
