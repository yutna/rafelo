# frozen_string_literal: true

module DummyEngine
  class DummyWidgetForm < Rafelo::Core::Form
    attribute :name, :string

    validates :name, presence: true, length: { maximum: 20 },
                     format: { with: /\A[a-z ]+\z/, allow_blank: true }
  end
end
