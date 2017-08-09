require "taxpub/exceptions"
require "taxpub/validator"
require "taxpub/version"
require "nokogiri"
require "open-uri"
require "set"

class Taxpub

  def initialize
    @parameters = {}
    @doc = {}
  end

  ##
  # View the built parameters
  #
  def params
    @parameters
  end

  ##
  # Specify a remote TaxPub URL
  # Source must be an xml file
  #
  # == Example
  #
  #   instance.url = "https://tdwgproceedings.pensoft.net/article/15141/download/xml/"
  #
  def url=(url)
    Validator.validate_url(url)
    @parameters[:url] = url
  end

  def url
    @parameters[:url] || nil
  end

  ##
  # Set a file path for a TaxPub XML file
  #
  # == Example
  #
  #   instance.file_path = "/Users/jane/Desktop/taxpub.xml"
  #
  def file_path=(file_path)
    Validator.validate_type(file_path, 'File')
    @parameters[:file] = File.new(file_path, "r")
  end

  def file_path
    @parameters[:file].path rescue nil
  end

  ##
  # Build the Nokogiri document
  #
  def parse
    if url
      @doc = Nokogiri::XML(open(url))
    elsif file_path
      @doc = File.open(file_path) { |f| Nokogiri::XML(f) }
    end
    Validator.validate_nokogiri(@doc)
  end

  ##
  # View the parsed Nokogiri document
  #
  def doc
    @doc
  end

  ##
  # Get the raw text content of the Nokogiri document
  #
  def content
    clean_text(@doc.text)
  end

  ##
  # Get the DOI
  #
  def doi
    Validator.validate_nokogiri(@doc)
    expand_doi(@doc.xpath("//*/article-meta/article-id[@pub-id-type='doi']").text)
  end

  ##
  # Get the title
  #
  def title
    Validator.validate_nokogiri(@doc)
    t = @doc.xpath("//*/article-meta/title-group/article-title").text
    clean_text(t)
  end

  ##
  # Get the abstract
  #
  def abstract
    Validator.validate_nokogiri(@doc)
    a = @doc.xpath("//*/article-meta/abstract").text
    clean_text(a)
  end

  ##
  # Get the keywords
  #
  def keywords
    Validator.validate_nokogiri(@doc)
    @doc.xpath("//*/article-meta/kwd-group/kwd")
        .map{|a| clean_text(a.text)}
  end

  ##
  # Get the authors
  #
  def authors
    Validator.validate_nokogiri(@doc)
    data = []
    @doc.xpath("//*/contrib[@contrib-type='author']").each do |author|
      affiliations = []
      author.xpath("xref/@rid").each do |rid|
        xpath = "//*/aff[@id='#{rid}']/addr-line"
        affiliations << clean_text(@doc.xpath(xpath).text)
      end
      orcid = author.xpath("uri[@content-type='orcid']").text
      given = clean_text(author.xpath("name/given-names").text)
      surname = clean_text(author.xpath("name/surname").text)
      data << {
        given: given,
        surname: surname,
        fullname: [given, surname].join(" "),
        email: author.xpath("email").text,
        affiliations: affiliations,
        orcid: orcid
      }
    end
    data
  end

  ##
  # Get the conference part of a proceeding
  #
  def conference_part
    Validator.validate_nokogiri(@doc)
    xpath = "//*/subj-group[@subj-group-type='conference-part']/subject"
    coll = @doc.xpath(xpath).text
    clean_text(coll)
  end

  ##
  # Get the presenting author of a proceeding
  #
  def presenting_author
    Validator.validate_nokogiri(@doc)
    xpath = "//*/sec[@sec-type='Presenting author']/p"
    author = @doc.xpath(xpath).text
    clean_text(author)
  end

  ##
  # Get the corresponding author
  #
  def corresponding_author
    Validator.validate_nokogiri(@doc)
    xpath = "//*/author-notes/fn[@fn-type='corresp']/p"
    author_string = clean_text(@doc.xpath(xpath).text)
    author_string.gsub("Corresponding author: ", "").chomp(".")
  end

  ##
  # Get the ranked taxa
  #
  def ranked_taxa
    Validator.validate_nokogiri(@doc)
    names = Set.new
    @doc.xpath("//*//tp:taxon-name").each do |taxon|
      tp = {}
      taxon.children.each do |child|
        next if !child.has_attribute?("taxon-name-part-type")
        rank = child.attributes["taxon-name-part-type"].value.to_sym
        if child.has_attribute?("reg")
          tp[rank] = child.attributes["reg"].value
        else
          tp[rank] = child.text
        end
      end
      names.add(tp)
    end
    names.to_a
  end

  def occurrences
    Validator.validate_nokogiri(@doc)
    data = []
    @doc.xpath("//*/list[@list-content='occurrences']/list-item").each do |occ|
      obj = {}
      occ.xpath("*/named-content").each do |dwc|
        prefix = dwc.attributes["content-type"].text.gsub(/dwc\:/, "")
        obj[prefix.to_sym] = dwc.text
      end
      data << obj
    end
    data
  end

  ##
  # Get the cited references
  #
  def references
    Validator.validate_nokogiri(@doc)
    xpath = "//*/ref-list/ref"
    @doc.xpath(xpath).map{ |r| parse_ref(r) }
  end

  private

  def clean_text(text)
    text.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => " ")
        .gsub(/[[:space:]]/, " ")
        .chomp(",")
        .split
        .join(" ")
  end

  def expand_doi(doi)
    if doi[0..2] == "10."
      doi.prepend("https://doi.org/")
    end
    doi
  end

  def authors_to_string(auths)
    authors = auths.dup
    return "" if authors.empty?
    first = authors.first.values.join(", ")
    authors.shift
    remaining = authors.map{|a| a.values.reverse.join(" ")}.join(", ")
    [first, remaining].reject(&:empty?).join(", ")
  end

  def parse_ref(ref)
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
      doi = expand_doi(ele.xpath("pub-id[@pub-id-type='doi']").text)
      uri = ele.xpath("uri").text
    end

    if ref.at_xpath("mixed-citation")
      doi = expand_doi(ele.xpath("ext-link[@ext-link-type='doi']").text)
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
        authors_to_string(auths),
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

end