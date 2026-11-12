# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    authorize :home, :show?
    render inertia: "home/index", props: { message: t("app.home.message") }
  end
end
