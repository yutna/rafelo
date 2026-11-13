require "rails_helper"

RSpec.describe "Action Pack patch version" do
  PATCHED_VERSION = "8.1.4.1".freeze

  def resolved_version
    Gem.loaded_specs.fetch("actionpack").version.to_s
  end

  def assert_patch_version!(resolved:, written_for: PATCHED_VERSION)
    return if resolved == written_for

    raise "actionpack patch was written for #{written_for}, but the resolved version is #{resolved}; drop, keep, or rewrite the patch"
  end

  it "records the version the redirect log patch was written for" do
    expect(resolved_version).to eq(PATCHED_VERSION)
    expect { assert_patch_version!(resolved: resolved_version) }.not_to raise_error
  end

  it "fails at runtime when the resolved version changes" do
    allow(Gem.loaded_specs).to receive(:fetch).with("actionpack")
      .and_return(double(version: Gem::Version.new("8.1.4.2")))

    expect { assert_patch_version!(resolved: resolved_version) }
      .to raise_error(/written for 8\.1\.4\.1.*resolved version is 8\.1\.4\.2/)
  end
end
