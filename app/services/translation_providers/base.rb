module TranslationProviders
  class Base
    def translate(content, to:, format: :text)
      raise NotImplementedError
    end

    def self.available?
      raise NotImplementedError
    end

    def supported_languages
      []
    end

    def quota_error?(error)
      false
    end

    def self.provider_name
      name.demodulize.downcase
    end
  end
end
