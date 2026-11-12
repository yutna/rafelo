# frozen_string_literal: true

module Rafelo
  module Core
    PageContext = Data.define(:viewer, :permissions, :flags, :locale, :request_id, :urls)
  end
end
