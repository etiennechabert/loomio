require 'net/http'
require 'json'

module TranslationProviders
  class Azure < Base
    ENDPOINT = 'https://api.cognitive.microsofttranslator.com'

    def self.available?
      ENV['AZURE_TRANSLATOR_KEY'].present?
    end

    def translate(content, from:, to:, format: :text)
      uri = build_uri(to, format)
      request = build_request(uri, content)
      response = execute_request(uri, request)
      parse_response(response)
    end

    def supported_languages
      []
    end

    def normalize_locale(locale)
      locale.to_s.downcase.gsub("_", "-").split("-")[0]
    end

    private

    def build_uri(to, format)
      query = "api-version=3.0&to=#{to}"
      query += "&textType=html" if format == :html
      URI("#{ENDPOINT}/translate?#{query}")
    end

    def build_request(uri, content)
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Ocp-Apim-Subscription-Key'] = ENV['AZURE_TRANSLATOR_KEY']
      request['Ocp-Apim-Subscription-Region'] = ENV['AZURE_TRANSLATOR_REGION'] if ENV['AZURE_TRANSLATOR_REGION']
      request.body = [{ 'Text' => content }].to_json
      request
    end

    def execute_request(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    end

    def parse_response(response)
      JSON.parse(response.body)[0]['translations'][0]['text']
    end
  end
end
