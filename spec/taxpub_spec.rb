RSpec.configure do |c|
  c.include Helpers, :include_helpers
end

describe "Taxpub", :include_helpers do
  subject { Taxpub }
  let(:tps) { subject.new }

  describe ".version" do
    it "returns version" do
      expect(subject.version).to match /\d+\.\d+\.\d+/
    end
  end

  describe ".new" do
    it "works" do
      expect(tps).to be_kind_of Taxpub
    end
  end

  describe ".parse" do
    it "converts an XML doc to Nokogiri::XML::Document" do
      expect(parsed_proceedings_stub.doc).to be_kind_of Nokogiri::XML::Document
    end
  end


  describe "#params" do

    context "url" do
      it "accepts a valid URL" do
        url = "https://tdwgproceedings.pensoft.net/article/15141/download/xml/"
        tps.url = url
        expect(tps.url).to eq(url)
      end
      it "it raises exception with invalid URL" do
        url = "ftp://tdwgproceedings.pensoft.net/article/15141/download/xml/"
        expect{tps.url = url}.to raise_error(subject::InvalidParameterValueError)
      end
    end

    context "file_path" do
      it "accepts a valid file_path" do
        file_path = File.join(__dir__, "files", "tdwgproceedings.pensoft.net.xml")
        tps.file_path = file_path
        expect(tps.file_path).to eq(file_path)
      end
      it "raises an exception for an invalid file_path" do
        file_path = File.join(__dir__, "files", "none.txt")
        expect{tps.file_path = file_path}.to raise_error(subject::InvalidParameterValueError)
      end
    end

  end

  describe "#parse" do

    context "doi" do
      it "outputs a DOI from a proceeding" do
        doi = "https://doi.org/10.3897/tdwgproceedings.1.19829"
        expect(parsed_proceedings_stub.doi).to eq(doi)
      end
      it "outputs a DOI from a paper" do
        doi = "https://doi.org/10.3897/zookeys.686.11711"
        expect(parsed_paper_stub.doi).to eq(doi)
      end
      it "raises an Exception if the document is not yet parsed" do
        tps = Taxpub.new
        tps.file_path = File.join(__dir__, "files", "zookeys.pensoft.net.xml")
        expect{tps.doi}.to raise_error(subject::InvalidTypeError)
      end
    end

    context "title" do
      it "outputs a title from a proceeding" do
        title = "Proposed Extension to Darwin Core"
        expect(parsed_proceedings_stub.title).to start_with(title)
      end
      it "outputs a title from a paper" do
        title = "A new species of Longicoelotes (Araneae, Agelenidae)"
        expect(parsed_paper_stub.title).to start_with(title)
      end
    end

    context "abstract" do
      it "outputs an abstract from a proceeding" do
        abstract = "The Global Biodiversity Information Facility's 2017-2021"
        expect(parsed_proceedings_stub.abstract).to start_with(abstract)
      end
      it "outputs an abstract from a paper" do
        abstract = "A new Longicoeletes species is described from Jiangxi Province, China"
        expect(parsed_paper_stub.abstract).to start_with(abstract)
      end
    end

    context "presenting author" do
      it "outputs the presenting author from a proceeding" do
        presenting_author = "David Peter Shorthouse"
        expect(parsed_proceedings_stub.presenting_author).to eq(presenting_author)
      end
      it "outputs an empty presenting author from a paper" do
        presenting_author = "David Peter Shorthouse"
        expect(parsed_paper_stub.presenting_author).to be_empty
      end
    end

    context "corresponding author" do
      it "outputs the corresponding author from a proceeding" do
        corresponding_author = "David Peter Shorthouse (davidpshorthouse@gmail.com)"
        expect(parsed_proceedings_stub.corresponding_author).to eq(corresponding_author)
      end
      it "outputs the corresponding author from a paper" do
        corresponding_author = "Zhe Zhao (zhaozhe@ioz.ac.cn)"
        expect(parsed_paper_stub.corresponding_author).to eq(corresponding_author)
      end
    end

    context "conference part" do
      it "outputs a conference part from a proceeding" do
        collection = "24 Other Oral Presentations"
        expect(parsed_proceedings_stub.conference_part).to eq(collection)
      end
      it "outputs a conference part from a paper" do
        collection = "24 Other Oral Presentations"
        expect(parsed_paper_stub.conference_part).to be_empty
      end
    end

    context "authors" do
      it "output authors from a proceeding" do
        author = {
          given: "David Peter",
          surname: "Shorthouse",
          fullname: "David Peter Shorthouse",
          email: "davidpshorthouse@gmail.com",
          affiliations: ["Canadian Museum of Nature, Ottawa, Canada"],
          orcid: "https://orcid.org/0000-0001-7618-5230"
        }
        expect(parsed_proceedings_stub.authors.first).to eq(author)
      end
      it "output authors from a proceeding without an affiliation" do
        author = {
          given: "Fabien",
          surname: "Cavière",
          fullname: "Fabien Cavière",
          email: "caviere@gbif.fr",
          affiliations: [],
          orcid: ""
        }
        expect(parsed_proceedings_2_stub.authors.first).to eq(author)
      end
      it "output authors from a paper without email, affiliation, orcid" do
        author = {
          given: "Xiaoqing",
          surname: "Zhang",
          fullname: "Xiaoqing Zhang",
          email: "",
          affiliations: [
            "Institute of Zoology",
            "Chinese Academy of Sciences, Beijing 100101, China"
          ],
          orcid: ""
        }
        expect(parsed_paper_stub.authors.first).to eq(author)
      end
    end

    context "keywords" do
      it "output keywords from a proceeding" do
        keywords = [
          "Darwin Core extension",
          "ORCID",
          "role",
          "attribution",
          "collections",
          "curator"
        ]
        expect(parsed_proceedings_stub.keywords).to eq(keywords)
      end
      it "output keywords from a proceeding that doesn't have any" do
        keywords = []
        expect(parsed_proceedings_2_stub.keywords).to eq(keywords)
      end
      it "output keywords from a paper" do
        keywords = [
          "East Asia",
          "description",
          "Coelotinae",
          "taxonomy"
        ]
        expect(parsed_paper_stub.keywords).to eq(keywords)
      end
    end

    context "ranked taxa" do
      it "output taxa from a proceeding" do
        taxa = []
        expect(parsed_proceedings_stub.ranked_taxa).to eq(taxa)
      end
      it "output taxa from a paper" do
        species = {:genus => "Longicoelotes", :species => "kulianganus"}
        expect(parsed_paper_stub.ranked_taxa.count).to eq(31)
        expect(parsed_paper_stub.ranked_taxa[3]).to eq(species)
      end
    end

    context "references" do
      it "output no references from a proceeding if there aren't any" do
        references = []
        expect(parsed_proceedings_stub.references).to eq(references)
      end
      it "output references from a proceeding" do
        refs = parsed_proceedings_3_stub.references
        expect(refs.count).to eq(3)
        doi = "https://doi.org/10.1023/A:1011438729881"
        expect(refs[1][:doi]).to eq(doi)
      end
      it "output reference dois from a paper" do
        refs = parsed_paper_stub.references
        expect(refs.count).to eq(10)
        cit = "World Spider Catalog. 2017. World Spider Catalog. http://wsc.nmbe.ch"
        expect(refs[7][:full_citation]).to eq(cit)

        cit = "Zhao, Z, S Li. 2016. Papiliocoelotes gen. n., a new genus of "\
              "Coelotinae (Araneae, Agelenidae) spiders from the Wuling "\
              "Mountains, China. ZooKeys 585: 33--50. "\
              "https://doi.org/10.3897/zookeys.585.8007"
        expect(refs[8][:full_citation]).to eq(cit)

      end
    end

  end

end
