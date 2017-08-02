require "taxpub/exceptions"
require "taxpub/validator"
require "taxpub/version"
require "nokogiri"
require "open-uri"
require "set"
require "byebug"

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
    a = @doc.xpath("//*/article-meta/abstract/p").text
    clean_text(a)
  end

  ##
  # Get the keywords
  #
  def keywords
    Validator.validate_nokogiri(@doc)
    @doc.xpath("//*/article-meta/kwd-group/kwd").map(&:text)
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
        affiliation: affiliations.join(", "),
        orcid: orcid
      }
    end
    data
  end

  ##
  # Get the conference part if a proceedings
  #
  def conference_part
    Validator.validate_nokogiri(@doc)
    xpath = "//*/subj-group[@subj-group-type='conference-part']/subject"
    coll = @doc.xpath(xpath).text
    clean_text(coll)
  end

  ##
  # Get the presenting author if a proceedings
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

  ##
  # Get the DOIs from reference list
  #
  def reference_dois
    Validator.validate_nokogiri(@doc)
    xpath = "//*/ref-list/ref/*/ext-link[@ext-link-type='doi']"
    ext_link = @doc.xpath(xpath)
                   .map{ |a| expand_doi(a.text) }

    xpath = "//*/ref-list/ref/*/pub-id[@pub-id-type='doi']"
    pub_id = @doc.xpath(xpath)
                 .map{ |a| expand_doi(a.text) }

    (ext_link + pub_id).uniq
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

end