# frozen_string_literal: true

module Rafelo
  module Core
    class BasePolicy
      attr_reader :user, :record

      def initialize(user, record = nil)
        @user = user
        @record = record
      end

      def permissions
        return user.permissions if user.respond_to?(:permissions)

        Current.permissions
      end

      def index? = false
      def show? = false
      def create? = false
      def new? = create?
      def update? = false
      def edit? = update?
      def destroy? = false
    end
  end
end
