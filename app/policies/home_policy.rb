# frozen_string_literal: true

class HomePolicy < Rafelo::Core::BasePolicy
  def show? = true
  def missing? = false
end
