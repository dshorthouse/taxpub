class TaxPub
  class Error < RuntimeError; end
  class InvalidParameterValueError < TaxPub::Error; end
  class InvalidTypeError < TypeError; end
end