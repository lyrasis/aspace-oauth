# frozen_string_literal: true

ArchivesSpace::Application.routes.draw do
  scope AppConfig[:frontend_proxy_prefix] do
    # OMNIAUTH GENERATED ROUTES:
    # OMNIAUTH:      /auth/:provider
    # OMNIAUTH-SAML: /auth/saml/metadata
    # OMNIAUTH-SAML: /auth/saml/slo
    # OMNIAUTH-SAML: /auth/saml/spslo

    get  '/auth/:provider/callback', to: 'oauth#create'
    post '/auth/:provider/callback', to: 'oauth#create'
    get  '/auth/failure',            to: 'oauth#failure'
    get  '/auth/cas_logout',         to: 'oauth#cas_logout'
    get  '/auth/saml_logout',        to: 'oauth#saml_logout'
  end
end
