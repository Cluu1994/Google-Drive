require 'google_drive'
module Middleman
  module Gdrive
    class Gauth

      def session
        # Create Google Authentication Session with Access Token
        settings = YAML.load(File.open('data/credentials.yml'))
        client = OAuth2::Client.new(
        settings['google']['client_id'], settings['google']['client_secret'],
          :site => 'https://accounts.google.com',
          :token_url => '/o/oauth2/token',
          :authorize_url => '/o/oauth2/auth'
        )
        auth_token = OAuth2::AccessToken.from_hash(client, {refresh_token: settings['google']['refresh_token']})
        auth_token = auth_token.refresh!
        session = GoogleDrive.login_with_oauth(auth_token)
        return session
      end

    end
  end
end
