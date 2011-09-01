module Mediafire
  class Error < StandardError; end

  # HTTP status code 400
  class BadRequest < StandardError; end
  # HTTP status code 401
  class Unauthorized < StandardError; end
  # HTTP status code 403
  class Forbidden < StandardError; end
  # HTTP status code 404
  class NotFound < StandardError; end
  # HTTP status code 406
  class NotAcceptable < StandardError; end
  # HTTP status code 408
  class RequestTimeout < StandardError; end
  # HTTP status code 500
  class InternalServerError < StandardError; end
  # HTTP status code 502
  class BadGateway < StandardError; end
  # HTTP status code 503
  class ServiceUnavailable < StandardError; end

  class NeedLogin < Error; end
end
