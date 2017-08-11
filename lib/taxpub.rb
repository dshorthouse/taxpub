require "taxpub/exceptions"
require "taxpub/validator"
require "taxpub/utils"
require "taxpub/reference"
require "taxpub/version"
require "nokogiri"
require "open-uri"
require "set"
require "byebug"

class TaxPub

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
    @doc
  end

  ##
  # View the parsed Nokogiri document
  #
  def doc
    @doc
  end

  def type
    Validator.validate_nokogiri(@doc)
    xpath = "/article/@article-type"
    @doc.xpath(xpath).text
  end

  ##
  # Get the raw text content of the Nokogiri document
  #
  def content
    Validator.validate_nokogiri(@doc)
    Utils.clean_text(@doc.text)
  end

  ##
  # Get the DOI
  #
  def doi
    Validator.validate_nokogiri(@doc)
    xpath = "//*/article-meta/article-id[@pub-id-type='doi']"
    Utils.expand_doi(@doc.xpath(xpath).text)
  end

  ##
  # Get the title
  #
  def title
    Validator.validate_nokogiri(@doc)
    xpath = "//*/article-meta/title-group/article-title"
    t = @doc.xpath(xpath).text
    Utils.clean_text(t)
  end

  ##
  # Get the abstract
  #
  def abstract
    Validator.validate_nokogiri(@doc)
    xpath = "//*/article-meta/abstract"
    a = @doc.xpath(xpath).text
    Utils.clean_text(a)
  end

  ##
  # Get the keywords
  #
  def keywords
    Validator.validate_nokogiri(@doc)
    xpath = "//*/article-meta/kwd-group/kwd"
    @doc.xpath(xpath)
        .map{|a| Utils.clean_text(a.text)}
  end

  ##
  # Get the authors
  #
  def authors
    Validator.validate_nokogiri(@doc)
    data = []
    xpath = "//*/contrib[@contrib-type='author']"
    @doc.xpath(xpath).each do |author|
      affiliations = []
      author.xpath("xref/@rid").each do |rid|
        xpath = "//*/aff[@id='#{rid}']/addr-line"
        affiliations << Utils.clean_text(@doc.xpath(xpath).text)
      end
      orcid = author.xpath("uri[@content-type='orcid']").text
      given = Utils.clean_text(author.xpath("name/given-names").text)
      surname = Utils.clean_text(author.xpath("name/surname").text)
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
  # Get the corresponding author
  #
  def corresponding_author
    Validator.validate_nokogiri(@doc)
    xpath = "//*/author-notes/fn[@fn-type='corresp']/p"
    author_string = Utils.clean_text(@doc.xpath(xpath).text)
    author_string.gsub("Corresponding author: ", "").chomp(".")
  end

  ##
  # Get the conference metadata
  #
  def conference
    Validator.validate_nokogiri(@doc)
    xpath = "//*/conference"
    conf = @doc.xpath(xpath)
    return {} if conf.empty?
    session_xpath = "//*/subj-group[@subj-group-type='conference-part']/subject"
    session = Utils.clean_text(@doc.xpath(session_xpath).text)
    presenter_xpath = "//*/sec[@sec-type='Presenting author']/p"
    presenter = Utils.clean_text(@doc.xpath(presenter_xpath).text)
    {
      date: Utils.clean_text(conf.at_xpath("conf-date").text),
      name: Utils.clean_text(conf.at_xpath("conf-name").text),
      acronym: Utils.clean_text(conf.at_xpath("conf-acronym").text),
      location: Utils.clean_text(conf.at_xpath("conf-loc").text),
      theme: Utils.clean_text(conf.at_xpath("conf-theme").text),
      session: session,
      presenter: presenter
    }
  end

  ##
  # Get the taxa
  #
  # == Attributes
  #
  # * +hsh+ - Hash { with_ranks: true } for scientific names returned with ranks as keys
  #
  def scientific_names(hsh = {})
    if hsh[:with_ranks]
      scientific_names_with_ranks
    else
      scientific_names_with_ranks.map{ |s| s.values.join(" ") }
    end
  end


  ##
  # Get occurrences with dwc keys
  #
  def occurrences
    Validator.validate_nokogiri(@doc)
    data = []
    xpath = "//*/list[@list-content='occurrences']/list-item"
    @doc.xpath(xpath).each do |occ|
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
  # Get the figures
  #
  def figures
    Validator.validate_nokogiri(@doc)
    data = []
    xpath = "//*/fig"
    @doc.xpath(xpath).each do |fig|
      data << {
        label: Utils.clean_text(fig.xpath("label").text),
        caption: Utils.clean_text(fig.xpath("caption").text),
        graphic: {
          href: fig.xpath("graphic").attribute("href").text,
          id: fig.xpath("graphic").attribute("id").text
        }
      }
    end
    data
  end

  ##
  # Get the cited references
  #
  def references
    Validator.validate_nokogiri(@doc)
    xpath = "//*/ref-list/ref"
    @doc.xpath(xpath).map{ |r| Reference.parse(r) }
  end

  private

  ##
  # Get the ranked taxa
  #
  def scientific_names_with_ranks
    Validator.validate_nokogiri(@doc)
    names = Set.new
    xpath = "//*//tp:taxon-name"
    @doc.xpath(xpath).each do |taxon|
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

end
