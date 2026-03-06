require 'spec_helper'

RSpec.describe SitemapGenerator::Sitemap do
  subject { described_class }

  describe "method missing" do
    it "should not be public" do
      expect(subject.methods).to_not include :method_missing
    end

    it "responds properly" do
      expect(subject.method :default_host).to be_a Method
    end
  end
end
