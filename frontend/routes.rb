ArchivesSpace::Application.routes.draw do

  scope AppConfig[:frontend_proxy_prefix] do
    # OMNIAUTH GENERATED ROUTES:
    # OMNIAUTH:      /auth/:provider
    # OMNIAUTH-SAML: /auth/saml/metadata

    get  '/auth/:provider/callback', to: 'oauth#create'
    post '/auth/:provider/callback', to: 'oauth#create'
    get  '/auth/failure',            to: 'oauth#failure'
  end

end
