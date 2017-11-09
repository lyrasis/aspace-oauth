# ArchivesSpace Oauth

Configure ArchivesSpace as a service provider (SP) for oauth authentication.

Strategies (tested or being tested =):

- [CAS](https://github.com/dlindahl/omniauth-cas)
- Developer [built-in for testing]
- [Google](https://github.com/zquestz/omniauth-google-oauth2)
- [SAML](https://github.com/omniauth/omniauth-saml)

__Google is included for convenient testing with a remote IDP service.__

## Overview

Enabling this plugin will:

- Provide Identity Provider (IDP) Sign In link/s
- The link will redirect the user to the IDP login portal
- If successful the user will have a user record created in ArchivesSpace
- User group membership and permissions are handled within ArchivesSpace
- The oauth plugin handles authentication only

## Configuration

```ruby
# example for developer and google
AppConfig[:authentication_sources] = [
  {
    model: 'ASOauth',
    provider: 'developer',
    label: 'Sign In Developer',
    config: {},
  },
  {
    model: 'ASOauth',
    provider: 'google_oauth2',
    label: 'Sign In with Google',
    config: {},
  },
]

# add the plugin to the list
AppConfig[:plugins] << "aspace-oauth"
```

Add / change providers as needed and refer to the project documentation
for configuration details.

## Developer

```bash
./build/run bundler -Dgemfile=../plugins/aspace-oauth/Gemfile
```

## License

This project is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

---