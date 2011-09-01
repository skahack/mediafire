# coding: utf-8

require 'nokogiri'
require 'mediafire/connection'
require 'mediafire/store_object'
require 'mediafire/error'
require 'mediafire/client'

module Mediafire
  class << self
    def new()
      Mediafire::Client.new()
    end
  end
end
