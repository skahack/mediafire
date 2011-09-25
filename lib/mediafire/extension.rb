
module Net
  class HTTPGenericRequest
    def upload_size
      @upload_size = 0 if @upload_size.nil?
      @upload_size
    end

    private

    def send_request_with_body_stream(sock, ver, path, f)
      unless content_length() or chunked?
        raise ArgumentError,
          "Content-Length not given and Transfer-Encoding is not `chunked'"
      end
      @upload_size = 0 if @upload_size.nil?
      supply_default_content_type
      write_header sock, ver, path
      if chunked?
        while s = f.read(1024)
          @upload_size += s.length
          sock.write(sprintf("%x\r\n", s.length) << s << "\r\n")
        end
        sock.write "0\r\n\r\n"
      else
        while s = f.read(1024)
          @upload_size += s.length
          sock.write s
        end
      end
    end
  end
end
