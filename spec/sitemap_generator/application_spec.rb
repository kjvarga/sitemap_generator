require 'spec_helper'

describe SitemapGenerator::Application do
  before :all do
    SitemapGenerator::Utilities.with_warnings(nil) do
      Object.const_set(:Rails, Object)
      Object::Rails.const_set(:Railtie, Object)
    end
  end

  after :all do
    SitemapGenerator::Utilities.with_warnings(nil) do
      Object.const_set(:Rails, nil)
    end
  end

  before :each do
    @app = SitemapGenerator::Application.new
  end

  describe "rails3?" do
    tests = {
      :nil => false,
      '2.3.11' => false,
      '3.0.1' => true,
      '3.0.11' => true
    }

    it "should identify the rails version correctly" do
      tests.each do |version, result|
        Rails.expects(:version).returns(version)
        @app.rails3?.should == result
      end
    end
  end

  describe "with Rails" do
    before :each do
      @root = '/test'
      Rails.expects(:root).returns(@root).at_least_once
    end

    it "should use the Rails.root" do
      @app.root.should be_a(Pathname)
      @app.root.to_s.should == @root
      (@app.root + 'public/').to_s.should == File.join(@root, 'public/')
    end
  end

  describe "with no Rails" do
    before :each do
      @rails = Rails
      Object.send(:remove_const, :Rails)
    end

    after :each do
      Object::Rails = @rails
    end

    it "should not be Rails" do
      @app.rails?.should be_false
    end

    it "should use the current working directory" do
      @app.root.should be_a(Pathname)
      @app.root.to_s.should == Dir.getwd
      (@app.root + 'public/').to_s.should == File.join(Dir.getwd, 'public/')
    end
  end
end
