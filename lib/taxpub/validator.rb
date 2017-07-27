require "uri"

class Taxpub
  class Validator

    def self.validate_url(data)
      validate_type(data, 'String')
      if data !~ /\A#{URI::regexp(['http', 'https'])}\z/
        raise InvalidParameterValue, "URL must be in the form http:// or https://"
      end
    end

    def self.validate_nokogiri(data)
      raise InvalidTypeError, "Must be a Nokogiri XML document" unless data.is_a? Nokogiri::XML::Document
    end

    def self.validate_type(data, type)
      case type
      when 'String', 'Array', 'Integer', 'Hash'
        raise InvalidParameterValue, "Must be a #{type}" unless data.is_a?(Object.const_get(type))
      when 'Boolean'
        raise InvalidParameterValue, "Must be a Boolean" unless [true, false].include?(data)
      when 'File'
        raise InvalidParameterValue, "Must be a file path & file must exist" unless File.file?(data)
      end
    end

  end
end