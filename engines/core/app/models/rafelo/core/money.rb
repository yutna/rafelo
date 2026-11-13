# frozen_string_literal: true

module Rafelo
  module Core
    # Currency exponents for wire money values (CT-02). The default is the
    # ISO 4217 minor-unit exponent of 2; the exceptions are explicit.
    module Money
      EXPONENTS = {
        "BHD" => 3, "IQD" => 3, "JOD" => 3, "KWD" => 3, "LYD" => 3, "OMR" => 3, "TND" => 3,
        "CLF" => 4, "UYW" => 4,
        "BIF" => 0, "CLP" => 0, "DJF" => 0, "GNF" => 0, "ISK" => 0, "JPY" => 0,
        "KMF" => 0, "KRW" => 0, "PYG" => 0, "RWF" => 0, "UGX" => 0, "UYI" => 0,
        "VND" => 0, "VUV" => 0, "XAF" => 0, "XOF" => 0, "XPF" => 0
      }.freeze

      def self.exponent(currency)
        EXPONENTS.fetch(currency.to_s.upcase, 2)
      end

      def self.wire(minor, currency)
        { minor: minor, currency: currency.to_s.upcase, exponent: exponent(currency) }
      end
    end
  end
end
