# frozen_string_literal: true

class ComponentCatalogProps < Rafelo::Core::PageProps
  def envelope
    { data: {}, meta: {}, query: {}, pagination: nil, can: {} }
  end
end
