# frozen_string_literal: true

class Content < ActiveRecord::Base
  validates_presence_of :title
end
