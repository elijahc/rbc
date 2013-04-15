module BSI
  # General exception
  class Error < StandardError

    attr_reader :message, :code
    attr_accessor :action
    def initialize(code=nil, message=nil, action=nil)
      @message  = message
      @code     = code
      @action   = action
    end

    def to_s
      "#{@code}: #{@message}"
    end

  end

  # Exception for broken pipes, or other low level odd eccentricities
  class IOError < Error; end
end
