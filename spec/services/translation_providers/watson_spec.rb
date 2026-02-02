require 'rails_helper'

RSpec.describe TranslationProviders::Watson do
  describe '.available?' do
    it 'returns true when both WATSON_TRANSLATOR_API_KEY and WATSON_TRANSLATOR_URL are set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_API_KEY').and_return('test-key')
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_URL').and_return('https://api.us-south.language-translator.watson.cloud.ibm.com')
      expect(TranslationProviders::Watson.available?).to eq true
    end

    it 'returns false when WATSON_TRANSLATOR_API_KEY is not set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_API_KEY').and_return(nil)
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_URL').and_return('https://api.us-south.language-translator.watson.cloud.ibm.com')
      expect(TranslationProviders::Watson.available?).to eq false
    end

    it 'returns false when WATSON_TRANSLATOR_URL is not set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_API_KEY').and_return('test-key')
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_URL').and_return(nil)
      expect(TranslationProviders::Watson.available?).to eq false
    end
  end

  describe '#translate' do
    let(:provider) { TranslationProviders::Watson.new }
    let(:api_response) { { 'translations' => [{ 'translation' => 'Bonjour' }] }.to_json }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_API_KEY').and_return('test-key')
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_URL').and_return('https://api.us-south.language-translator.watson.cloud.ibm.com')
    end

    it 'makes a POST request to Watson Language Translator API' do
      stub_request(:post, "https://api.us-south.language-translator.watson.cloud.ibm.com/v3/translate?version=2018-05-01")
        .with(
          body: { 'text' => ['Hello'], 'target' => 'FR' }.to_json,
          headers: {
            'Content-Type' => 'application/json'
          },
          basic_auth: ['apikey', 'test-key']
        )
        .to_return(status: 200, body: api_response)

      result = provider.translate('Hello', to: 'fr', format: :text)

      expect(result).to eq 'Bonjour'
    end

    it 'handles URLs with trailing slashes' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_API_KEY').and_return('test-key')
      allow(ENV).to receive(:[]).with('WATSON_TRANSLATOR_URL').and_return('https://api.us-south.language-translator.watson.cloud.ibm.com/')

      stub_request(:post, "https://api.us-south.language-translator.watson.cloud.ibm.com/v3/translate?version=2018-05-01")
        .to_return(status: 200, body: api_response)

      result = provider.translate('Hello', to: 'fr', format: :text)

      expect(result).to eq 'Bonjour'
    end

    it 'supports HTML format' do
      stub_request(:post, "https://api.us-south.language-translator.watson.cloud.ibm.com/v3/translate?version=2018-05-01")
        .with(body: { 'text' => ['<p>Hello</p>'], 'target' => 'FR' }.to_json)
        .to_return(status: 200, body: { 'translations' => [{ 'translation' => '<p>Bonjour</p>' }] }.to_json)

      result = provider.translate('<p>Hello</p>', to: 'fr', format: :html)

      expect(result).to eq '<p>Bonjour</p>'
    end
  end

  describe '#normalize_locale' do
    let(:provider) { TranslationProviders::Watson.new }

    it 'converts underscore to hyphen and returns base language' do
      expect(provider.normalize_locale('fr_CA')).to eq 'fr'
    end

    it 'returns locale if supported' do
      expect(provider.normalize_locale('fr')).to eq 'fr'
      expect(provider.normalize_locale('zh-tw')).to eq 'zh-tw'
    end

    it 'returns base language for unsupported variants' do
      expect(provider.normalize_locale('en-US')).to eq 'en'
      expect(provider.normalize_locale('pt-BR')).to eq 'pt'
    end

    it 'handles Chinese traditional' do
      expect(provider.normalize_locale('zh_TW')).to eq 'zh-tw'
    end
  end
end
