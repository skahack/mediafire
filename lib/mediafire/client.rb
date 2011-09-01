module Mediafire
  class Client
    require 'mediafire/api'
    include API
    
    attr_accessor :datas, :root_folder

    def initialize()
      @loggedin = false
      @cookie = {}

      @root_folder = nil

      toppage
    end
  end
end
