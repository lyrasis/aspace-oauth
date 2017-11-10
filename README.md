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
# example for testing from src: developer, google, saml
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
  {
    model: 'ASOauth',
    provider: 'saml',
    label: 'Institutional Sign In',
    config: {
      :assertion_consumer_service_url     => "http://localhost:3000/auth/saml/callback",
      :issuer                             => "http://localhost:3000",
      :idp_sso_target_url                 => "http://localhost/simplesaml/saml2/idp/SSOService.php",
      :idp_cert_fingerprint               => "119b9e027959cdb7c662cfd075d9e2ef384e445f",
      :idp_cert_fingerprint_validator     => lambda { |fingerprint| fingerprint },
      :name_identifier_format             => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
    },
]

# add the plugin to the list
AppConfig[:plugins] << "aspace-oauth"
```

Add / change providers as needed and refer to the project documentation
for configuration details.

For testing SAML there is a helpful docker image:

```bash
docker run --name=test-saml-idp -d \
  --net=host \
  -e SIMPLESAMLPHP_SP_ENTITY_ID=http://localhost:3000 \
  -e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=http://localhost:3000/auth/saml/callback \
  kristophjunge/test-saml-idp
```

The test SAML service will be available at: `http://localhost`.

## Developer

```bash
./build/run bundler -Dgemfile=../plugins/aspace-oauth/Gemfile
```

## License

This project is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

---