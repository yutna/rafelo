# frozen_string_literal: true

require "json"
require "net/http"
require "open3"
require "uri"

# Shared CODEOWNERS and review readers for the pull request checks (WF-03).
module Approvals
  RATCHET_FILES = [ "config/ratchets.yml", "engines/*/config/ratchets.yml" ].freeze

  module_function

  # CODEOWNERS is read from the merge base when one is given, so a pull
  # request cannot remove its own guard path or add an owner to approve
  # itself (WF-03). The value loads the file once for a whole diff.
  class Codeowners
    def self.load(root, base: nil)
      if base && !base.to_s.empty?
        %w[.github/CODEOWNERS CODEOWNERS].each do |candidate|
          output, status = Open3.capture2("git", "-C", root, "show", "#{base}:#{candidate}", err: File::NULL)
          return new(Approvals.parse_codeowners(output)) if status.success?
        end
        return new([])
      end

      path = File.join(root, ".github", "CODEOWNERS")
      path = File.join(root, "CODEOWNERS") unless File.file?(path)
      return new([]) unless File.file?(path)

      new(Approvals.parse_codeowners(File.read(path)))
    end

    def initialize(entries)
      @entries = entries.freeze
    end

    attr_reader :entries

    def owner_logins
      entries.flat_map { |entry| entry[:owners] }.uniq
    end

    def guard_entry?(path)
      return false if Approvals.ratchet_file?(path)

      entries.any? { |entry| Approvals.match?(entry[:pattern], path) }
    end
  end

  def codeowners(root, base: nil)
    Codeowners.load(root, base: base)
  end

  def parse_codeowners(text)
    text.lines(chomp: true).filter_map do |line|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?("#")

      pattern, *owners = stripped.split
      next if pattern.nil? || owners.empty?

      { pattern: pattern, owners: owners.map { |owner| owner.delete_prefix("@") } }
    end
  end

  def owner_logins(codeowners)
    codeowners.owner_logins
  end

  def normalize(pattern)
    pattern = pattern.delete_prefix("/")
    pattern = "#{pattern}**/*" if pattern.end_with?("/")
    pattern
  end

  # GitHub CODEOWNERS follows gitignore: a pattern without a slash matches at
  # any depth, and a leading slash anchors it to the repository root.
  def match?(pattern, path)
    normalized = normalize(pattern)
    anchored = pattern.start_with?("/") || normalized.include?("/")
    candidate = anchored ? normalized : "**/#{normalized}"

    File.fnmatch?(candidate, path, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH)
  end

  def guard_entry?(codeowners, path)
    codeowners.guard_entry?(path)
  end

  def ratchet_file?(path)
    File.fnmatch?("config/ratchets.yml", path) ||
      File.fnmatch?("engines/*/config/ratchets.yml", path, File::FNM_PATHNAME)
  end

  def changed_files(root, base)
    # Rename detection would hide a guard file moved to an unguarded path.
    output, status = Open3.capture2("git", "-C", root, "diff", "--name-only", "--no-renames", "#{base}...HEAD")
    abort "approvals: git diff failed for base #{base}" unless status.success?

    output.lines.map(&:strip).reject(&:empty?)
  end

  def reviews(file: nil, pr: nil, repository: nil)
    return JSON.parse(File.read(file)) if file

    abort "approvals: PR_NUMBER or HEAD_REF is required to read reviews" if pr.nil? || pr.to_s.empty?
    abort "approvals: GITHUB_REPOSITORY is required to read reviews" if repository.to_s.empty?

    api_get("/repos/#{repository}/pulls/#{pr}/reviews?per_page=100") do |path|
      output, status = Open3.capture2("gh", "api", "--paginate", "--slurp", path, err: File::NULL)
      JSON.parse(output).flatten(1) if status.success?
    end
  end

  def latest_states(reviews)
    reviews.each_with_object({}) do |review, states|
      login = review.dig("user", "login")
      next if login.nil?

      state = review["state"].to_s.upcase
      next unless %w[APPROVED CHANGES_REQUESTED DISMISSED].include?(state)

      states[login] = state
    end
  end

  # An approval counts only when its author is not the pull request author
  # (WF-03): an agent or owner cannot approve its own change.
  def pull_request_author(repository:, number:)
    return if repository.to_s.empty? || number.to_s.empty?

    value = api_get("/repos/#{repository}/pulls/#{number}") do |path|
      output, status = Open3.capture2("gh", "api", path, "--jq", ".user.login", err: File::NULL)
      output.strip if status.success?
    end
    value.is_a?(Hash) ? value.dig("user", "login") : value
  end

  # CI has no pull-request permission by default. Use the authenticated gh
  # client when it works, then the public API (the check fails closed if the
  # repository is private and no token is available).
  def api_get(path)
    value = begin
      yield(path)
    rescue Errno::ENOENT
      nil
    end
    return value unless value.nil?

    public_api_get(path)
  rescue JSON::ParserError
    abort "approvals: GitHub API returned invalid JSON for #{path}"
  end

  def public_api_get(path)
    results = []
    page = 1
    loop do
      separator = path.include?("?") ? "&" : "?"
      uri = URI("https://api.github.com#{path}#{separator}per_page=100&page=#{page}")
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/vnd.github+json"
        request["User-Agent"] = "rafelo-ci"
        http.request(request)
      end
      abort "approvals: GitHub API failed for #{path}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      return body unless body.is_a?(Array)

      results.concat(body)
      break unless response["link"].to_s.include?('rel="next"')

      page += 1
    end
    results
  end

  def approved_by_owner?(codeowners, reviews, author: nil)
    owners = codeowners.owner_logins
    states = latest_states(reviews)
    return false if states.values.include?("CHANGES_REQUESTED")

    author = author.to_s.strip.downcase
    return false if author.empty?

    states.any? do |login, state|
      next false unless state == "APPROVED"
      next false unless owners.any? { |owner| owner.casecmp?(login) }

      !login.casecmp?(author)
    end
  end

  def pull_request_number(pr, head_ref)
    return pr if pr && !pr.to_s.empty?

    match = head_ref.to_s.match(%r{/pr-(\d+)(?:-|$)})
    match && match[1]
  end
end
