module TranslationProviders
  class Base
    def translate(content, from:, to:, format: :text)
      raise NotImplementedError
    end

    def self.available?
      raise NotImplementedError
    end

    def supported_languages
      []
    end
  end
end
