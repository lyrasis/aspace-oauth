# Changelog

All notable changes to this project will be documented in this file.
## [Unreleased]

### Changes

- Use jruby for tests and add more for auth (#56)
- Use cliff to generate changelog
## [4.0.0-1] - 2025-08-20

### Bug Fixes

- fix cas logout dropdown link as it was off kilter by leveraging class dropdown-item (#54)

### Features

- Allow for an alt config for SAML SLO (#49)

### Reverted

- Revert "Pr/dl maura/49 (#51)" (#52)
## [4.0.0] - 2025-04-08

### Dependencies

- Pin addressable for v4.0.0 compatibility
- Bump omniauth-saml (addresses ruby-saml cve)
- Update login link

### Other

- test fixt for formatting
- header needs to be fixed again
- align right
## [3.5.1] - 2024-10-29

### Features

- Add standard, overcommit and gh action for linting
- Add debug option as appconfig

### Other

- Make sure those keys last more than a month
## [3.5.0] - 2024-06-17

### Changes

- Remove rexml from gemfile

### Dependencies

- Pin rexml version

### Other

- Relax Gemfile version constraints
- Support deployments with separate back/frontend
- Document the :oauth_shared_secret config option
- Re-apply header_global template changes to latest version
## [3.2.0] - 2022-06-03

### Features

- Add option to use email as username
## [3.1.1] - 2022-01-05

### Dependencies

- Update Gemfile
## [2.8.1] - 2021-09-01

### Bug Fixes

- Fix SLO with SUI path prefix

### Dependencies

- Update docs
- Update SAML example
- Update crt / key generation docs (google method)
- Update omniauth-cas to v2.0.0

### Features

- Add google oauth
- Add google auth
- Add SAML example
- Add install docs
- Add SAML metadata parser url doc
- Add metadata parser option
- Added uid_key and email_key and linked to omniauth-cas for more options
- Allow username to be set from uid attribute of auth_hash

### Other

- Minimum viable plugin
- Match on downcased name
- Support use of multiple providers
- A CAS Example
- Base email value on omniauth :extra info if not present in :info
- Include gems and don't commit lock
- Ignore lock
- Clarify plugin is for SP authn via delegation to IDP
- Show docs for encrypted assertions
- Provide ability to resolve digest and signature methods (saml)
- More saml docs
- Backend can expect info email as it's forced by the frontend
- Move email gathering into private method and ensure backend gets it
- Example using SAML attr statement to set info email
- Consolidate read from info in backend
- Generate link using frontend prefix
- Implement matching_usernames to fix typeahead
- CAS logout
- SAML slo
- Utilized omniauth-cas default values for uid_key and email_key
- Option to disable idp ssl verify
- Set additional user info if available
- Force downcase of usernames created via the plugin, fixes #18
- Locks addressable to 2.7

