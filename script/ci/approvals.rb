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
    # GitHub's search order: .github/, the root, then docs/.
    LOCATIONS = %w[.github/CODEOWNERS CODEOWNERS docs/CODEOWNERS].freeze

    def self.load(root, base: nil)
      if base && !base.to_s.empty?
        validate_base!(root, base)
        LOCATIONS.each do |candidate|
          listing, status = Open3.capture2(
            "git", "-C", root, "ls-tree", "--name-only", base, "--", candidate, err: File::NULL
          )
          abort "approvals: cannot list #{candidate} at #{base}" unless status.success?
          next if listing.strip.empty?

          output, show_status = Open3.capture2(
            "git", "-C", root, "show", "#{base}:#{candidate}", err: File::NULL
          )
          abort "approvals: cannot read #{candidate} at #{base}" unless show_status.success?

          return new(Approvals.parse_codeowners(output))
        end
        return new([])
      end

      LOCATIONS.each do |candidate|
        path = File.join(root, candidate)
        return new(Approvals.parse_codeowners(File.read(path))) if File.file?(path)
      end
      new([])
    end

    def self.validate_base!(root, base)
      _output, status = Open3.capture2(
        "git", "-C", root, "rev-parse", "--verify", "#{base}^{commit}", err: File::NULL
      )
      abort "approvals: invalid base #{base}" unless status.success?
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

  # GitHub CODEOWNERS follows gitignore: a leading slash anchors the pattern,
  # a pattern without a slash matches at any depth, and a pattern that names a
  # directory owns everything below it (github.com docs, "CODEOWNERS syntax").
  def normalize(pattern)
    body = pattern.delete_prefix("/")
    body = body.delete_suffix("/**") if body.end_with?("/**")
    body = body.delete_suffix("/") if body.end_with?("/")
    [ body, pattern.end_with?("/") || pattern.end_with?("/**") ]
  end

  def anchored?(pattern)
    pattern.start_with?("/") || pattern.delete_prefix("/").delete_suffix("/").include?("/")
  end

  def match?(pattern, path)
    normalized, directory = normalize(pattern)
    return false if normalized.empty?

    base = anchored?(pattern) ? normalized : "**/#{normalized}"
    last = normalized.split("/").last.to_s
    directory ||= !last.match?(/[*?\[\]{}]/)
    candidates = [ base ]
    candidates << "#{base}/**/*" if directory

    candidates.any? do |candidate|
      File.fnmatch?(candidate, path, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH)
    end
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
    # NUL separation keeps git from quoting a non-ASCII, spaced, or quoted
    # path, which would otherwise hide a guard file from the matcher (WF-03).
    output, status = Open3.capture2(
      "git", "-C", root, "diff", "--name-only", "-z", "--no-renames", "#{base}...HEAD"
    )
    abort "approvals: git diff failed for base #{base}" unless status.success?

    output.split("\0").reject(&:empty?)
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
  # (WF-03): an agent or owner cannot approve its own change. The merge_group
  # payload has no pull request user, so the author is resolved from the PR
  # number; a missing gh fails closed with nil instead of reaching the network.
  def pull_request_author(repository:, number:)
    return if repository.to_s.empty? || number.to_s.empty?

    output, status = Open3.capture2(
      "gh", "api", "repos/#{repository}/pulls/#{number}", "--jq", ".user.login", err: File::NULL
    )
    login = output.strip
    status.success? && !login.empty? ? login : nil
  rescue Errno::ENOENT
    nil
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
