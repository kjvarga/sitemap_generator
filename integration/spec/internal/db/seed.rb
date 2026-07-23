# frozen_string_literal: true

if Content.none?
  (1..10).each do |i|
    Content.create!(title: "content #{i}")
  end
end
