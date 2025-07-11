# ArchivesSpace Oauth

Configure ArchivesSpace as a service provider (SP) for oauth authentication.
_The plugin delegates authentication to the configured identity provider (IDP)._

Strategies tested:

- [CAS](https://github.com/dlindahl/omniauth-cas)
- Developer [built-in for testing]
- [SAML](https://github.com/omniauth/omniauth-saml)

## Overview

Enabling this plugin will:

- Provide Identity Provider (IDP) Sign In link/s
- The link will redirect the user to the IDP login portal
- If successful the user will have a user record created in ArchivesSpace
- User group membership and permissions are handled within ArchivesSpace
- The oauth plugin handles (by delegating) authentication only

## Installation

Download this plugin to `$ARCHIVESSPACE_DIR/plugins` and initialize it:

```bash
cd /path/to/archivesspace/plugins
# with wget and unzip
wget https://github.com/lyrasis/aspace-oauth/archive/master.zip
unzip master.zip
mv aspace-oauth-master aspace-oauth

# or with git
git clone https://github.com/lyrasis/aspace-oauth.git

# now download the gems
cd /path/to/archivesspace
./scripts/initialize-plugin.sh aspace-oauth
```

## Configuration

```ruby
# example for testing from src: developer, saml
AppConfig[:authentication_sources] = [
  {
    model: 'ASOauth',
    provider: 'developer',
    label: 'Sign In Developer',
    slo_link: false,
    config: {},
  },
  {
    model: 'ASOauth',
    provider: 'saml',
    label: 'Institutional Sign In',
    slo_link: false,
    # METADATA URL: optional, use to download configuration
    # metadata_parser_url: "https://login.somewhere.edu:4443/idp/shibboleth",
    config: {
      :assertion_consumer_service_url     => "http://localhost:3000/auth/saml/callback",
      :issuer                             => "http://localhost:3000/auth/saml/metadata",
      :name_identifier_format             => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
      # THESE ARE OPTIONAL IF USING METADATA URL (but can be used to override parsed metadata)
      :idp_sso_target_url                 => "http://localhost/simplesaml/saml2/idp/SSOService.php",
      :idp_cert_fingerprint               => "119b9e027959cdb7c662cfd075d9e2ef384e445f",
      :idp_cert_fingerprint_validator     => lambda { |fingerprint| fingerprint },
      # OPTIONAL: for encrypted assertions
      :certificate                        => "PUBLIC CERT",
      :private_key                        => "PRIVATE KEY",
      # OPTIONAL: may be required by IDP (used with certificate and private_key)
      :security                           => {
        authn_requests_signed:     true,
        want_assertions_signed:    true,
        want_assertions_encrypted: true,
        metadata_signed:           true,
        # XMLSecurity::Document strings for digest and signature will be resolved to constant
        digest_method:             "XMLSecurity::Document::SHA256",
        signature_method:          "XMLSecurity::Document::RSA_SHA256",
        embed_sign:                true,
      },
      :attribute_statements => {
        email: ["urn:oid:0.9.2342.19200300.100.1.3"],
      },
    }
  },
  {
    model: 'ASOauth',
    provider: 'cas',
    label: 'CAS Sign In',
    slo_link: true,
    config: {
      url: 'https://login.ivory-tower.edu',
      host: 'login.ivory-tower.edu',
      ssl: true,
      login_url: '/cas/login',
      logout_url: '/cas/logout',
      service_validate_url: '/cas/serviceValidate',
      uid_key: 'user',
      email_key: 'email'
      # more cas keys and options at: https://github.com/dlindahl/omniauth-cas
      #
      # if your server does not return an email address, you can add one
      # here using the fetch_raw_info option.
      fetch_raw_info: ->(s, o, t, user_info) {  { email: "#{user_info['user']}@ivory-tower.edu" } }
    }
  }
]

# add the plugin to the list
AppConfig[:plugins] << "aspace-oauth"

# Most people can ignore this. If the ArchivesSpace frontend and backend are
# deployed separately (not the default), both frontend and backend need the same
# value for :oauth_shared_secret in order to validate login requests between the
# frontend and backend. Set this to a long password-like random value.
# When not set, a value is generated automatically and shared inside the JVM
# using a system property.
#AppConfig[:oauth_shared_secret] = "00000000-0000-0000-0000-000000000000"
```

Add / change providers as needed and refer to the project documentation
for configuration details. There are many more configuration options than shown
above.

For testing SAML there is a helpful docker image:

```bash
docker run --name=test-saml-idp -d \
  --net=host \
  -e SIMPLESAMLPHP_SP_ENTITY_ID=http://localhost:3000 \
  -e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=http://localhost:3000/auth/saml/callback \
  kristophjunge/test-saml-idp
```

The test SAML service will be available at: `http://localhost`.

## SAML

To generate a cert / key use a command like:

```bash
openssl genrsa -out rsaprivkey.pem 2048
openssl req -new -x509 -nodes -days 3650 -key rsaprivkey.pem -out rsacert.pem
```

## Developer

```bash
./build/run bundler -Dgemfile=../plugins/aspace-oauth/Gemfile
```

### Testing

This plugin includes a test suite using minitest. Since this is an ArchivesSpace plugin, testing requires setup to mock ArchivesSpace dependencies.

```bash
# Install development dependencies
bundle install --gemfile=Gemfile.dev

# Run tests
bundle exec --gemfile=Gemfile.dev rake test

# Run tests with linting
bundle exec --gemfile=Gemfile.dev rake quality

# Run individual test file
bundle exec --gemfile=Gemfile.dev ruby -Itest test/unit/aspace_oauth_test.rb
```

The test suite uses a separate `Gemfile.dev` to avoid conflicts with the main Gemfile, which is designed for the ArchivesSpace context. Tests mock the `AppConfig` module and other ArchivesSpace dependencies.

For linting:

```bash
# install overcommit for git precommit hooks
gem install overcommit && overcommit --install && overcommit --sign pre-commit
bundle exec --gemfile=Gemfile.dev rake lint_fix
```

## License

This project is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

---
