# frozen_string_literal: true

Dir["#{File.dirname(__FILE__)}/core_ext/**/*.rb"].sort.each do |path|
  require path
end
