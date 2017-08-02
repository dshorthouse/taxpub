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

  def parse
    if url
      @doc = Nokogiri::XML(open(url))
    elsif file_path
      @doc = File.open(file_path) { |f| Nokogiri::XML(f) }
    end
    Validator.validate_nokogiri(@doc)
  end

  def doc
    @doc
  end

  def doi
    Validator.validate_nokogiri(@doc)
    expand_doi(@doc.xpath("//*/article-meta/article-id[@pub-id-type='doi']").text)
  end

  def title
    Validator.validate_nokogiri(@doc)
    t = @doc.xpath("//*/article-meta/title-group/article-title").text
    clean_text(t)
  end

  def abstract
    Validator.validate_nokogiri(@doc)
    a = @doc.xpath("//*/article-meta/abstract/*/p").text
    clean_text(a)
  end

  def keywords
    Validator.validate_nokogiri(@doc)
    @doc.xpath("//*/article-meta/kwd-group/kwd").map(&:text) rescue []
  end

  def authors
    Validator.validate_nokogiri(@doc)
    data = []
    @doc.xpath("//*/contrib[@contrib-type='author']").each do |author|
      rid = author.xpath("xref").attr("rid").value rescue nil
      affiliation = nil
      if !rid.nil?
        affiliation = clean_text(@doc.xpath("//*/aff[@id='#{rid}']/addr-line").text)
      end
      orcid = author.xpath("uri[@content-type='orcid']").text rescue nil
      given = clean_text(author.xpath("name/given-names").text)
      surname = clean_text(author.xpath("name/surname").text)
      data << { 
        given: given,
        surname: surname,
        fullname: [given, surname].join(" "),
        email: author.xpath("email").text,
        affiliation: affiliation,
        orcid: orcid
      }
    end
    data
  end

  def conference_part
    Validator.validate_nokogiri(@doc)
    coll = @doc.xpath("//*/subj-group[@subj-group-type='conference-part']/subject").text
    clean_text(coll)
  end

  def presenting_author
    Validator.validate_nokogiri(@doc)
    author = @doc.xpath("//*/sec[@sec-type='Presenting author']/p").text
    clean_text(author)
  end

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

  def reference_dois
    Validator.validate_nokogiri(@doc)
    ext_link = @doc.xpath("//*/ref-list/ref/*/ext-link[@ext-link-type='doi']")
                   .map(&:text)
                   .map{ |a| expand_doi(a) }
    pub_id = @doc.xpath("//*/ref-list/ref/*/pub-id[@pub-id-type='doi']")
                 .map(&:text)
                 .map{ |a| expand_doi(a) }
    (ext_link + pub_id).uniq
  end

  private

  def clean_text(text)
    text.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => " ")
        .gsub(/[[:space:]]/, " ")
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