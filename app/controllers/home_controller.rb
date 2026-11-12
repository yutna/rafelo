# frozen_string_literal: true

class HomeController < ApplicationController
  def show
    render inertia: "home/index", props: { message: "Rafelo" }
  end
end
