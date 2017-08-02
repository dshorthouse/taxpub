class Taxpub
  class Error < RuntimeError; end
  class InvalidParameterValueError < Taxpub::Error; end
  class InvalidTypeError < TypeError; end
end