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

    def forbidden
      authorize :home, :show?
      send_download(
        filename: "report.txt",
        source: ->(&_block) { raise Pundit::NotAuthorizedError }
      )
    end

    def many_chunks
      authorize :home, :show?
      send_download(
        filename: "many.txt",
        source: ->(&block) { 20.times { |index| block.call("chunk-#{index}\n") } }
      )
    end

    def empty
      authorize :home, :show?
      send_download(
        filename: "empty.txt",
        type: "text/plain",
        source: ->(&_block) { }
      )
    end

    def streamed
      authorize :home, :show?
      send_download(
        filename: "stream.txt",
        type: "text/plain",
        source: lambda do |&block|
          Rafelo::Core::UpstreamClient.for(
            :api,
            config: Rails.application.config.x.upstreams.fetch(:api),
            token_provider: Rafelo::Core::Current.token_provider,
            budget: Rafelo::Core::Current.call_budget
          ).stream(:get, "downloads/1") { |chunk| block.call(chunk) }
        end
      )
    end
  end
end
