module Mediafire
  class Client
    require 'mediafire/api'
    include API
    
    attr_accessor :datas, :root_folder

    def initialize()
      @loggedin = false
      @cookie = {}
      @s_queue = Queue.new
      @r_queue = Queue.new

      @root_folder = nil

      toppage
    end
  end
end
