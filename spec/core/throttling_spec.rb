require "rails_helper"

RSpec.describe Rafelo::Core::Throttling do
  let(:controller_class) do
    Class.new(ApplicationController) do
      def create = render(plain: "ok")

      def destroy = render(plain: "ok")
    end
  end

  it "records each action's named limit" do
    controller_class.throttle to: 5, within: 1.minute, only: :create
    controller_class.throttle to: 2, within: 1.minute, only: :destroy, name: "destroy/ip"

    expect(controller_class.throttle_limits[:create]).to eq([ { name: "create", to: 5, within: 1.minute } ])
    expect(controller_class.throttle_limits[:destroy]).to eq([ { name: "destroy/ip", to: 2, within: 1.minute } ])
  end

  it "rejects a second limit with the same name on one action" do
    controller_class.throttle to: 5, within: 1.minute, only: :create, name: "shared"

    expect do
      controller_class.throttle to: 1, within: 1.minute, only: :create, name: "shared"
    end.to raise_error(ArgumentError, /already has a limit named/)
  end

  it "prepends every limit before the base callbacks" do
    callbacks = SessionsController._process_action_callbacks.to_a
    load_session = callbacks.index { |callback| callback.kind == :before && callback.filter == :load_session }
    limit_indexes = callbacks.each_index.select do |index|
      callback = callbacks[index]
      callback.kind == :before && callback.filter.respond_to?(:source_location) &&
        callback.filter.source_location&.first&.end_with?("rate_limiting.rb")
    end

    expect(limit_indexes).not_to be_empty
    expect(limit_indexes.max).to be < load_session
  end
end
