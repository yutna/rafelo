Rafelo::Core::UpstreamClient.for(:api)
Rafelo::Core::ScopedCache.fetch(scope: :public, owner: :core, key: "x", ttl: 1.minute) { 1 }
Rafelo::Core::ReturnTo.from(params, locale: :en)
