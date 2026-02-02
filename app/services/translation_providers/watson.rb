require 'net/http'
require 'json'

module TranslationProviders
  class Watson < Base
    SUPPORTED_LOCALES = %w[ar bg bn bs ca cs da de el en es et fa fi fr ga gu he hi hr hu id is it ja ko lt lv ml ms mt nb ne nl nn no pa pl pt ro ru sk sl sq sr sv ta te th tr uk ur vi zh zh-tw]
    API_VERSION = '2018-05-01'

    def self.available?
      ENV['WATSON_TRANSLATOR_API_KEY'].present? && ENV['WATSON_TRANSLATOR_URL'].present?
    end

    def translate(content, to:, format: :text)
      uri = build_uri
      request = build_request(uri, content, to, format)
      response = execute_request(uri, request)
      parse_response(response)
    end

    def supported_languages
      SUPPORTED_LOCALES
    end

    def normalize_locale(locale)
      locale = locale.to_s.downcase.gsub("_", "-")
      return locale if SUPPORTED_LOCALES.include?(locale)
      base_locale = locale.split("-")[0]
      return base_locale if SUPPORTED_LOCALES.include?(base_locale)
      base_locale
    end

    private

    def build_uri
      url = ENV['WATSON_TRANSLATOR_URL'].chomp('/')
      URI("#{url}/v3/translate?version=#{API_VERSION}")
    end

    def build_request(uri, content, to, format)
      request = Net::HTTP::Post.new(uri)
      request.basic_auth('apikey', ENV['WATSON_TRANSLATOR_API_KEY'])
      request['Content-Type'] = 'application/json'

      body = {
        'text' => [content],
        'target' => to.upcase
      }

      request.body = body.to_json
      request
    end

    def execute_request(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    end

    def parse_response(response)
      JSON.parse(response.body)['translations'][0]['translation']
    end
  end
end
