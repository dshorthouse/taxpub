require "uri"

class Taxpub
  class Validator

    def self.validate_url(data)
      validate_type(data, 'String')
      if data !~ /\A#{URI::regexp(['http', 'https'])}\z/
        raise InvalidParameterValueError, "URL must be in the form http:// or https://"
      end
    end

    def self.validate_nokogiri(data)
      if !data.is_a?(Nokogiri::XML::Document)
        raise InvalidTypeError, "Must be a Nokogiri XML document or the parse method has not been executed"
      end
    end

    def self.validate_type(data, type)
      case type
      when 'String', 'Array', 'Integer', 'Hash'
        raise InvalidParameterValueError, "Must be a #{type}" unless data.is_a?(Object.const_get(type))
      when 'Boolean'
        raise InvalidParameterValueError, "Must be a Boolean" unless [true, false].include?(data)
      when 'File'
        raise InvalidParameterValueError, "Must be a file path & file must exist" unless File.file?(data)
      end
    end

  end
end