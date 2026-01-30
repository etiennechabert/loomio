require 'rails_helper'

RSpec.describe TranslationProviders::Azure do
  describe '.available?' do
    it 'returns true when AZURE_TRANSLATOR_KEY is set' do
      allow(ENV).to receive(:[]).with('AZURE_TRANSLATOR_KEY').and_return('test-key')
      expect(TranslationProviders::Azure.available?).to eq true
    end

    it 'returns false when AZURE_TRANSLATOR_KEY is not set' do
      allow(ENV).to receive(:[]).with('AZURE_TRANSLATOR_KEY').and_return(nil)
      expect(TranslationProviders::Azure.available?).to eq false
    end
  end

  describe '#translate' do
    let(:provider) { TranslationProviders::Azure.new }
    let(:api_response) { [{ 'translations' => [{ 'text' => 'Bonjour', 'to' => 'fr' }] }].to_json }

    before do
      allow(ENV).to receive(:[]).with('AZURE_TRANSLATOR_KEY').and_return('test-key')
      allow(ENV).to receive(:[]).with('AZURE_TRANSLATOR_REGION').and_return(nil)
    end

    it 'makes a POST request to Azure Translator API' do
      stub_request(:post, "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&to=fr")
        .with(
          body: [{ 'Text' => 'Hello' }].to_json,
          headers: {
            'Content-Type' => 'application/json',
            'Ocp-Apim-Subscription-Key' => 'test-key'
          }
        )
        .to_return(status: 200, body: api_response)

      result = provider.translate('Hello', from: 'en', to: 'fr', format: :text)

      expect(result).to eq 'Bonjour'
    end

    it 'includes region header when AZURE_TRANSLATOR_REGION is set' do
      allow(ENV).to receive(:[]).with('AZURE_TRANSLATOR_REGION').and_return('eastus')

      stub_request(:post, "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&to=fr")
        .with(
          headers: {
            'Content-Type' => 'application/json',
            'Ocp-Apim-Subscription-Key' => 'test-key',
            'Ocp-Apim-Subscription-Region' => 'eastus'
          }
        )
        .to_return(status: 200, body: api_response)

      provider.translate('Hello', from: 'en', to: 'fr', format: :text)
    end

    it 'supports HTML format' do
      stub_request(:post, "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0&textType=html&to=fr")
        .with(body: [{ 'Text' => '<p>Hello</p>' }].to_json)
        .to_return(status: 200, body: [{ 'translations' => [{ 'text' => '<p>Bonjour</p>' }] }].to_json)

      result = provider.translate('<p>Hello</p>', from: 'en', to: 'fr', format: :html)

      expect(result).to eq '<p>Bonjour</p>'
    end
  end

  describe '#normalize_locale' do
    it 'converts underscore to hyphen and returns base language' do
      provider = TranslationProviders::Azure.new
      expect(provider.normalize_locale('zh_CN')).to eq 'zh'
    end

    it 'returns base language for locale variants' do
      provider = TranslationProviders::Azure.new
      expect(provider.normalize_locale('fr-CA')).to eq 'fr'
    end
  end
end
