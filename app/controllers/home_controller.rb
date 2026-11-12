# frozen_string_literal: true

class HomeController < ApplicationController
  skip_after_action :verify_authorized

  def show
    render inertia: "home/index", props: { message: t("app.home.message") }
  end
end
