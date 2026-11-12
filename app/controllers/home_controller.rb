# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    render inertia: "home/index", props: { message: t("app.home.message") }
  end
end
