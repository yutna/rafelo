# frozen_string_literal: true

module RuboCop
  module Cop
    module Rafelo
      # Dates are formatted only by the kernel formatter (FE-20).
      class DateFormatterOnly < Base
        MSG = "Rafelo/DateFormatterOnly: format dates only in Rafelo::Core::DateFormatter (FE-20)."
        RESTRICT_ON_SEND = %i[strftime to_fs to_formatted_s l].freeze

        def on_send(node)
          name = Matching.method_name(node)
          if name == "l"
            receiver = node.receiver
            return if receiver.nil? || (Matching.const_name(receiver) == "I18n" && !receiver.absolute?)
          end

          add_offense(node.loc.selector)
        end
      end
    end
  end
end
