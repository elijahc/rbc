# BSI Exceptions
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

module BSIServices
  class Base
    include Marshaling

    def add_methods(methods)
      methods.each do |meth|
        define_singleton_method meth, ->(*arguments) {build_call("#{self.class.to_s.split('::').last.downcase}.#{__method__}", *arguments) }
      end
    end

  end

  class Test < Base
    def initialize
      add_methods(%w(add echo))
    end
  end

end
