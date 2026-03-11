require 'spec_helper'

RSpec.describe SitemapGenerator::Sitemap do
  subject { described_class }

  it "has a class name" do
    expect(subject.class.name).to match "SitemapGenerator::"
  end

  describe "method missing" do
    it "should not be public" do
      expect(subject.methods).to_not include :method_missing
    end

    it "responds properly" do
      expect(subject.method :default_host).to be_a Method
    end

    it "respects inheritance" do
      subject.class.include Module.new {
        def method_missing(*args) = :inherited
        def respond_to_missing?(name, *) = name == :something_inherited
      }

      expect(subject).to respond_to :something_inherited
      expect(subject.linkset_doesnt_know).to be :inherited
    end

    it "delegates private methods" do
      expect { subject.add_default_links }.to_not raise_error
    end
  end
end
