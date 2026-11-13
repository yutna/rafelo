require "rails_helper"

RSpec.describe Rafelo::Core::Form do
  let(:form_class) do
    Class.new(described_class) do
      attribute :first_name, :string
      attribute :line_items, :string

      validates :first_name, presence: true
    end
  end

  it "exposes the payload without the form token" do
    form = form_class.new(first_name: "Ada", token: "one-time")

    expect(form.payload).to eq(first_name: "Ada")
  end

  it "camelizes shape errors and translates upstream codes" do
    form = form_class.new(first_name: "")
    expect(form.error_messages).to eq("firstName" => "can't be blank")

    translated = form.translate("firstName" => :too_long, "mystery" => :taken)
    expect(translated).to eq("firstName" => "is too long", "base" => "has already been taken")
  end
end
