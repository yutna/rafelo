# frozen_string_literal: true

require "json"
require "open3"

# Shared CODEOWNERS and review readers for the pull request checks (WF-03).
module Approvals
  RATCHET_FILES = [ "config/ratchets.yml", "engines/*/config/ratchets.yml" ].freeze

  module_function

  def codeowners(root)
    path = File.join(root, ".github", "CODEOWNERS")
    path = File.join(root, "CODEOWNERS") unless File.file?(path)
    return [] unless File.file?(path)

    File.readlines(path, chomp: true).filter_map do |line|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?("#")

      pattern, *owners = stripped.split
      next if pattern.nil? || owners.empty?

      { pattern: pattern, owners: owners.map { |owner| owner.delete_prefix("@") } }
    end
  end

  def owner_logins(root)
    codeowners(root).flat_map { |entry| entry[:owners] }.uniq
  end

  def normalize(pattern)
    pattern = pattern.delete_prefix("/")
    pattern = "#{pattern}**/*" if pattern.end_with?("/")
    pattern
  end

  def match?(pattern, path)
    normalized = normalize(pattern)
    return true if File.fnmatch?(normalized, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
    return true if normalized.end_with?("**/*") && path.start_with?(normalized.delete_suffix("**/*"))

    File.fnmatch?(normalized, path, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH)
  end

  def guard_entry?(root, path)
    return false if ratchet_file?(path)

    codeowners(root).any? { |entry| match?(entry[:pattern], path) }
  end

  def ratchet_file?(path)
    File.fnmatch?("config/ratchets.yml", path) ||
      File.fnmatch?("engines/*/config/ratchets.yml", path, File::FNM_PATHNAME)
  end

  def changed_files(root, base)
    output, status = Open3.capture2("git", "-C", root, "diff", "--name-only", "#{base}...HEAD")
    abort "approvals: git diff failed for base #{base}" unless status.success?

    output.lines.map(&:strip).reject(&:empty?)
  end

  def reviews(file: nil, pr: nil, repository: nil)
    return JSON.parse(File.read(file)) if file

    abort "approvals: PR_NUMBER or HEAD_REF is required to read reviews" if pr.nil? || pr.to_s.empty?
    abort "approvals: GITHUB_REPOSITORY is required to read reviews" if repository.to_s.empty?

    output, status = Open3.capture2(
      "gh", "api", "--paginate", "repos/#{repository}/pulls/#{pr}/reviews"
    )
    abort "approvals: gh api failed for pull request #{pr}" unless status.success?

    JSON.parse(output)
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

  def approved_by_owner?(root, reviews)
    owners = owner_logins(root)
    states = latest_states(reviews)
    return false if states.values.include?("CHANGES_REQUESTED")

    states.any? { |login, state| state == "APPROVED" && owners.include?(login) }
  end

  def pull_request_number(pr, head_ref)
    return pr if pr && !pr.to_s.empty?

    match = head_ref.to_s.match(%r{/pr-(\d+)(?:-|$)})
    match && match[1]
  end
end
