require 'uri'
require 'net/http'
require 'net/http/post/multipart'

Net::HTTP.version_1_1

module Mediafire
  module Connection
    ENDPOINT = 'http://www.mediafire.com/'

    def get(path, options={})
      request(:get, path, options)
    end

    def post(path, options={})
      request(:post, path, options)
    end

    def request(method, path, options)
      uri = URI.parse("#{ENDPOINT}#{path}")

      request = nil
      if method == :get
        request = Net::HTTP::Get.new(uri.request_uri)
      elsif method == :post
        if has_multipart? options
          request = Net::HTTP::Post::Multipart.new(uri.request_uri, options)
        else
          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(options)
        end
      end
      request['Cookie'] = cookie

      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
      build_cookie(response.get_fields('Set-Cookie'))

      return response
    end

    def has_multipart?(options)
      options.values.each do |v|
        if v.is_a? UploadIO
          return true
        end
      end
      false
    end
    
    private

    def check_statuscode(response)
      case response.code
      when 400
        raise BadRequest
      when 401
        raise Unauthorized
      when 403
        raise Forbidden
      when 404
        raise NotFound
      when 406
        raise NotAcceptable
      when 408
        raise RequestTimeout
      when 500
        raise InternalServerError
      when 502
        raise BadGateway
      when 503
        raise ServiceUnavailable
      end
    end

    def cookie
      s = []
      @cookie.each do |k,v|
        s.push "#{k}=#{v}"
      end
      s.join(';')
    end

    def build_cookie(cookies)
      cookies.each do |n|
        c = n[0...n.index(';')].match(/(.*)=(.*)/)
        @cookie[c[1]] = c[2] if c
      end if cookies
    end
  end
end
