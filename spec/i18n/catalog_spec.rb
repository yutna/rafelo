require "rails_helper"

RSpec.describe "Error catalog translations" do
  it "resolves every kernel error key in every configured locale" do
    Rafelo::Core::ErrorCatalog.entries.each_key do |code|
      key = Rafelo::Core::ErrorCatalog.fetch(code).fetch("i18n_key")
      Rafelo::Core::Locales.available.each do |locale|
        expect { I18n.t(key, locale: locale, fallback: false) }.not_to raise_error
        expect(I18n.t(key, locale: locale, fallback: false)).not_to include("translation missing")
      end
    end
  end
end
