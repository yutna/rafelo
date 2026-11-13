require "rails_helper"
require "socket"
require "timeout"

RSpec.describe "Upstream streaming limits" do
  let(:token) { Struct.new(:token, :service?).new("secret", false) }

  def with_server(handler)
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    thread = Thread.new do
      socket = server.accept
      socket.readpartial(4096)
      handler.call(socket)
    ensure
      socket&.close
      server.close
    end
    yield "http://127.0.0.1:#{port}"
  ensure
    thread&.join(2)
    server&.close
  end

  def config(port_url, max_bytes: 100, read_timeout: 2)
    Rafelo::Core::UpstreamConfig.new(
      base_url: port_url,
      open_timeout: 1,
      read_timeout: read_timeout,
      write_timeout: 1,
      max_concurrent_calls: 2,
      max_response_bytes: max_bytes,
      retry_budget: 0,
      idempotency_keys: false,
      service_token_gateways: [],
      breaker: { failure_threshold: 100, cool_off: 1 }
    )
  end

  it "aborts a chunked body above the byte cap" do
    WebMock.allow_net_connect!
    with_server(->(socket) do
      socket.write("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n")
      10.times { socket.write("20\r\n#{'x' * 32}\r\n") }
      socket.write("0\r\n\r\n")
    end) do |url|
      client = Rafelo::Core::UpstreamClient.new(name: :stream_cap, config: config(url, max_bytes: 50), token_provider: token)

      expect { client.get("invoices") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("unexpected") }
    end
  ensure
    WebMock.disable_net_connect!
  end

  it "aborts a trickling body at the deadline" do
    WebMock.allow_net_connect!
    with_server(->(socket) do
      socket.write("HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\n")
      20.times do
        socket.write("x" * 5)
        sleep 0.02
      end
    end) do |url|
      client = Rafelo::Core::UpstreamClient.new(
        name: :stream_deadline, config: config(url), token_provider: token,
        deadline: Rafelo::Core::RequestDeadline.new(0.1)
      )

      expect { client.get("invoices") }.to raise_error(Rafelo::Core::ApplicationError) { |error| expect(error.code).to eq("upstream.timeout") }
    end
  ensure
    WebMock.disable_net_connect!
  end
end

RSpec.describe "Upstream connection reuse" do
  let(:token) { Struct.new(:token, :service?).new("secret", false) }

  it "reuses one persistent connection for sequential calls" do
    WebMock.allow_net_connect!
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    accepts = 0
    thread = Thread.new do
      socket = server.accept
      accepts += 1
      2.times do
        socket.readpartial(4096)
        socket.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: keep-alive\r\n\r\n{}")
      end
      socket.close
    ensure
      server.close
    end
    config = Rafelo::Core::UpstreamConfig.new(
      base_url: "http://127.0.0.1:#{port}", open_timeout: 1, read_timeout: 2, write_timeout: 1,
      max_concurrent_calls: 2, max_response_bytes: 100, retry_budget: 0, idempotency_keys: false,
      service_token_gateways: [], breaker: { failure_threshold: 100, cool_off: 1 }
    )
    client = Rafelo::Core::UpstreamClient.new(name: :persistent, config: config, token_provider: token)

    Timeout.timeout(3) do
      2.times { expect(client.get("invoices").status).to eq(200) }
    end
    thread.join(2)

    expect(accepts).to eq(1)
  ensure
    thread&.kill
    server&.close
    WebMock.disable_net_connect!
  end
end
