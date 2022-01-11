(1..10).each do |i|
  Content.create!(:title => "content #{i}")
end if Content.count == 0
