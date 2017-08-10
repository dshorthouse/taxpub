class TaxPub
  class Utils

    def self.clean_text(text)
      text.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => " ")
          .gsub(/[[:space:]]/, " ")
          .chomp(",")
          .split
          .join(" ")
    end

    def self.expand_doi(doi)
      if doi[0..2] == "10."
        doi.prepend("https://doi.org/")
      end
      doi
    end

  end
end