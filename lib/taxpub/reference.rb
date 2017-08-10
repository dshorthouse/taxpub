class TaxPub
  class Reference

    def self.parse(ref)
      ele = ref.at_xpath("element-citation") || ref.at_xpath("mixed-citation")

      auths = []
      ele.xpath("person-group/name").each do |name|
        auths << { 
          surname: name.xpath("surname").text,
          given_names: name.xpath("given-names").text
        }
      end

      institution = ele.xpath("institution").text
      year = ele.xpath("year").text
      title = ele.xpath("article-title").text.chomp(".")
      source = ele.xpath("source").text.chomp(".")
      volume = ele.xpath("volume").text
      pages = [ele.xpath("fpage"), ele.xpath("lpage")].reject(&:empty?).join("–")

      if ref.at_xpath("element-citation")
        doi = Utils.expand_doi(ele.xpath("pub-id[@pub-id-type='doi']").text)
        uri = ele.xpath("uri").text
      end

      if ref.at_xpath("mixed-citation")
        doi = Utils.expand_doi(ele.xpath("ext-link[@ext-link-type='doi']").text)
        uri = ele.xpath("ext-link[@ext-link-type='uri']").text
      end

      link = !doi.empty? ? doi : uri

      {
        title: title,
        institution: institution,
        authors: auths,
        year: year,
        source: source,
        volume: volume,
        pages: pages,
        doi: doi,
        uri: uri,
        full_citation: [
          institution,
          self.authors_to_string(auths),
          year,
          title,
          [
            source,
            [volume, pages].reject(&:empty?).join(": ")
          ].reject(&:empty?).join(" "), 
          link
        ].reject(&:empty?).join(". ")
      }
    end

    def self.authors_to_string(auths)
      authors = auths.dup
      return "" if authors.empty?
      first = authors.first.values.join(", ")
      authors.shift
      remaining = authors.map{|a| a.values.reverse.join(" ")}.join(", ")
      [first, remaining].reject(&:empty?).join(", ")
    end

  end
end