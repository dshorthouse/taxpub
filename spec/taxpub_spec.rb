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
        expect{tps.url = url}.to raise_error(subject::InvalidParameterValue)
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
        expect{tps.file_path = file_path}.to raise_error(subject::InvalidParameterValue)
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

    context "presenting author" do
      it "outputs the presenting author from a proceeding" do
        presenting_author = "David Peter Shorthouse"
        expect(parsed_proceedings_stub.presenting_author).to eq(presenting_author)
      end
      it "outputs the presenting author from a paper" do
        presenting_author = "David Peter Shorthouse"
        expect(parsed_paper_stub.presenting_author).to be_empty
      end
    end

    context "collection" do
      it "outputs a collection from a proceeding" do
        collection = "24 Other Oral Presentations"
        expect(parsed_proceedings_stub.collection).to eq(collection)
      end
      it "outputs a collection from a paper" do
        collection = "24 Other Oral Presentations"
        expect(parsed_paper_stub.collection).to be_empty
      end
    end

    context "authors" do
      it "output authors from a proceeding" do
        author = "David Peter Shorthouse"
        expect(parsed_proceedings_stub.authors.first[:fullname]).to eq(author)
      end
      it "output authors from a paper" do
        author = "Xiaoqing Zhang"
        expect(parsed_paper_stub.authors.first[:fullname]).to eq(author)
      end
    end

    context "keywords" do
      it "output keywords from a proceeding" do
        keywords = ["Darwin Core extension", "ORCID", "role", "attribution", "collections", "curator"]
        expect(parsed_proceedings_stub.keywords).to eq(keywords)
      end
      it "output keywords from a paper" do
        keywords = ["East Asia", "description", "Coelotinae", "taxonomy"]
        expect(parsed_paper_stub.keywords).to eq(keywords)
      end
    end

    context "references with dois" do
      it "output reference dois from a proceeding" do
        dois = []
        expect(parsed_proceedings_stub.reference_dois).to eq(dois)
      end
      it "output reference dois from a paper" do
        dois = [
          "https://doi.org/10.5479/si.00963801.63-2481.1",
          "https://doi.org/10.1007/s13238-016-0318-x",
          "https://doi.org/10.1016/j.ympev.2010.02.021",
          "https://doi.org/10.2476/asjaa.49.165",
          "https://doi.org/10.1206/0003-0090(2002)269<0001:AGLROT>2.0.CO;2",
          "https://doi.org/10.3897/zookeys.585.8007",
          "https://doi.org/10.1371/journal.pone.0061814"
        ]
        expect(parsed_paper_stub.reference_dois).to eq(dois)
      end
    end

  end

end
