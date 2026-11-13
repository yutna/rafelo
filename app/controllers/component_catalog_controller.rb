# frozen_string_literal: true

class ComponentCatalogController < ApplicationController
  before_action :skip_authorization
  skip_after_action :verify_authorized

  def index
    render_page "component_catalog/index", props: ComponentCatalogProps.new(context: page_context)
  end
end
