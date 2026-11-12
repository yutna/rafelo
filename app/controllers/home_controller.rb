# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    authorize :home, :show?
    render_page "home/index",
                props: HomeIndexProps.new(context: page_context, message: t("app.home.message"))
  end
end
