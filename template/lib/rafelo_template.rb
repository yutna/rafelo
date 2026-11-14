# frozen_string_literal: true

# The application template's name rules, kept in a plain object so the
# Rails template and its specs share one implementation (GEN-07).
module RafeloTemplate
  RESERVED = %w[
    Core
    DesignSystem
    Rafelo
    Engines
    App
    ExampleOrders
    ExampleCustomers
  ].freeze

  module_function

  def namespace(app_name)
    app_name.to_s.split(/[_-]/).reject(&:empty?).map do |part|
      part[0].upcase + part[1..].to_s
    end.join
  end

  def reserved?(app_name)
    name = namespace(app_name)
    RESERVED.include?(name) || Object.const_defined?(name)
  end

  def validate!(app_name)
    name = namespace(app_name)
    if RESERVED.include?(name)
      raise ArgumentError, "template: #{app_name.inspect} collides with the reserved namespace #{name}"
    end
    if Object.const_defined?(name)
      raise ArgumentError, "template: #{app_name.inspect} is already a constant (#{name})"
    end

    name
  end
end
