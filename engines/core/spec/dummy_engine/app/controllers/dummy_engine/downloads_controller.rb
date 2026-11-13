# frozen_string_literal: true

module DummyEngine
  class DownloadsController < Rafelo::Core::DownloadController
    def show
      authorize :home, :show?
      send_download(
        filename: "../../report.txt",
        type: "text/plain",
        source: ->(&block) { block.call("hello"); block.call(" world") }
      )
    end

    def failure
      authorize :home, :show?
      send_download(
        filename: "report.txt",
        source: ->(&_block) { raise Rafelo::Core::ApplicationError.new("upstream.unavailable") }
      )
    end

    def overflow
      authorize :home, :show?
      send_download(
        filename: "overflow.txt",
        max_bytes: 5,
        source: ->(&block) { block.call("abc"); block.call("def") }
      )
    end
  end
end
