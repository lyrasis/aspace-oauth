# Upgrading

## v4.2.0

For this release all OmniAuth dependencies have been upgraded to their latest major versions:

- `omniauth` 1.x → 2.x
- `omniauth-cas` 2.x → 3.x
- `omniauth-rails_csrf_protection` 2.x (new dependency)
- `omniauth-saml` 1.x → 2.x

After upgrading, re-run `initialize-plugin.sh` to install the updated gems:

```bash
cd /path/to/archivesspace
./scripts/initialize-plugin.sh aspace-oauth
```

### SAML configuration changes

The following SAML configuration keys have been renamed. The old names still
work but are deprecated and may be removed in a future version of ruby-saml:


| Old Key | New Key |
|---|---|
| `:issuer` | `:sp_entity_id` |
| `:idp_sso_target_url` | `:idp_sso_service_url` |
| `:idp_slo_target_url` | `:idp_slo_service_url` |


The `:idp_cert_fingerprint_validator` option has been removed. If you are using
this option in your configuration, remove it.

### OmniAuth 2.x CSRF protection

OmniAuth 2.x defaults to allowing only POST requests for the authentication
request phase (previously GET and POST were allowed). The
`omniauth-rails_csrf_protection` gem has been added to bridge Rails' CSRF
protection with OmniAuth. Sign-in links now use POST forms automatically.

If you have custom links pointing directly to `/auth/<provider>` using GET
requests, they will need to be updated to use POST forms.

### CAS configuration

CAS configuration keys are unchanged. If you were using `uid_key` note that the
correct option name is `uid_field` (this was the case in prior versions as well).
