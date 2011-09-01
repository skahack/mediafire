# coding: utf-8
$:.unshift(File.dirname(__FILE__))

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
