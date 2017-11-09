# ArchivesSpace Oauth

Configure ArchivesSpace as a service provider for oauth user authentication.

Strategies:

- [CAS](https://github.com/dlindahl/omniauth-cas)
- Developer
- [SAML](https://github.com/omniauth/omniauth-saml)

## Overview

Enabling this plugin will:

- Provide an Institutional Sign In link
- The link will redirect the user to an Identity Provider login portal
- If successful the user will have a user record created in ArchivesSpace
- User group membership and permissions are handled within ArchivesSpace
- The oauth plugin handles authentication only

## Configuration

```ruby
AppConfig[:authentication_sources] = [{
  model: 'ASOauth',
  provider: 'developer',
  config: {},
}]

AppConfig[:plugins] << "aspace-oauth"
```

Change `provider` as needed and refer to the project documentation for
configuration details.

## Developer

```bash
./build/run bundler -Dgemfile=../plugins/aspace-oauth/Gemfile
```

---