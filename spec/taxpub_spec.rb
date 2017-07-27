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
      expect(parsed_stub.doc).to be_kind_of Nokogiri::XML::Document
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

    it "outputs a DOI" do
      doi = "https://doi.org/10.3897/tdwgproceedings.1.19829"
      expect(parsed_stub.doi).to eq(doi)
    end

    it "outputs a title" do
      title = "Proposed Extension to Darwin Core"
      expect(parsed_stub.title).to start_with(title)
    end

    it "outputs the presenting author" do
      presenting_author = "David Peter Shorthouse"
      expect(parsed_stub.presenting_author).to eq(presenting_author)
    end

    it "outputs a collection" do
      collection = "24 Other Oral Presentations"
      expect(parsed_stub.collection).to eq(collection)
    end

    it "output authors" do
      author = "David Peter Shorthouse"
      expect(parsed_stub.authors.first[:fullname]).to eq(author)
    end

    it "output keywords" do
      keywords = ["Darwin Core extension", "ORCID", "role", "attribution", "collections", "curator"]
      expect(parsed_stub.keywords).to eq(keywords)
    end

  end

end
