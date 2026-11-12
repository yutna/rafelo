# frozen_string_literal: true

Rails.application.config.x.executor.size = 4
Rails.application.config.x.requests.upstream_deadline_seconds = 10
Rails.application.config.x.sessions.refresh_timeout_seconds = 15
Rails.application.config.x.downloads.max_concurrent = 2
Rails.application.config.x.downloads.max_bytes = 52_428_800
