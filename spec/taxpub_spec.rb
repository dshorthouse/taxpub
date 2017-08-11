RSpec.configure do |c|
  c.include Helpers, :include_helpers
end

describe "TaxPub", :include_helpers do
  subject { TaxPub }
  let(:tps) { subject.new }

  describe ".version" do
    it "returns version" do
      expect(subject.version).to match /\d+\.\d+\.\d+/
    end
  end

  describe ".new" do
    it "works" do
      expect(tps).to be_kind_of TaxPub
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

    context "type" do
      it "outputs the article type from a proceeding" do
        type = "research-article"
        expect(parsed_proceedings_stub.type).to eq(type)
      end
    end

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
        tps = TaxPub.new
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
        abstract = "Abstract The Global Biodiversity Information Facility"
        expect(parsed_proceedings_stub.abstract).to start_with(abstract)
      end
      it "outputs an abstract from a paper" do
        abstract = "Abstract A new Longicoeletes species is described from Jiangxi Province, China"
        expect(parsed_paper_stub.abstract).to start_with(abstract)
      end
    end

    context "conference" do
      it "outputs the conference data" do
        conference = {
          acronym: "TDWG 2017",
          date: "1-6 October 2017",
          location: "Ottawa, Canada",
          name: "TDWG 2017 Annual Conference",
          theme: "Data Integration in a Big Data Universe: Associating Occurrences with Genes, Phenotypes, and Environments",
          session: "24 Other Oral Presentations",
          presenter: "David Peter Shorthouse"
        }
        expect(parsed_proceedings_stub.conference).to eq(conference)
      end
      it "outputs empty conference data when none exist" do
        expect(parsed_paper_stub.conference).to be_empty
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

    context "scientific names" do
      it "outputs scientific names from a proceeding" do
      end
      it "outputs taxa from a paper" do
        expect(parsed_paper_stub.scientific_names[1]).to eq("Araneae")
        expect(parsed_paper_stub.scientific_names.count).to eq(31)
      end
    end

    context "scientific names with ranks" do
      it "outputs scientific names with ranks from a proceeding" do
        names = []
        expect(parsed_proceedings_stub.scientific_names({with_ranks: true})).to eq(names)
      end
      it "outputs ranked taxa from a paper" do
        name = {:genus => "Longicoelotes", :species => "kulianganus"}
        expect(parsed_paper_stub.scientific_names({with_ranks: true}).count).to eq(31)
        expect(parsed_paper_stub.scientific_names({with_ranks: true})[3]).to eq(name)
      end
    end

    context "occurrences" do
      it "outputs occurrence records" do
        occurrence = {
          typeStatus: "Other material",
          occurrenceDetails: "http://www.boldsystems.org/index.php/API_Public/specimen?ids=ASHYM1999-13",
          catalogNumber: "DHJPAR0052645",
          recordNumber: "13-SRNP-18822",
          recordedBy: "Guillermo Pereira",
          individualID: "DHJPAR0052645",
          individualCount: "1",
          sex: "male",
          lifeStage: "adult",
          scientificName: "Vibrissina albopicta",
          nameAccordingTo: "(Bigot, 1889)",
          phylum: "Arthropoda",
          class: "Insecta",
          order: "Diptera",
          family: "Tachinidae",
          genus: "Vibrissina",
          specificEpithet: "albopicta",
          scientificNameAuthorship: "(Bigot, 1889)",
          continent: "Central America",
          country: "Costa Rica",
          stateProvince: "Guanacaste",
          county: "Sector Santa Rosa",
          locality: "Area de Conservación Guanacaste",
          verbatimLocality: "Area Administrativa",
          verbatimElevation: "295",
          verbatimLatitude: "10.83764",
          verbatimLongitude: "-85.61871",
          verbatimCoordinateSystem: "decimal",
          decimalLatitude: "10.8376",
          decimalLongitude: "-85.6187",
          identifiedBy: "A.J. Fleming",
          samplingProtocol: "Reared from the larva of Durgoa mattogrossensis",
          verbatimEventDate: "10-Aug-2013",
          institutionCode: "CNC"
        }
        expect(parsed_paper_2_stub.occurrences.count).to eq(88)
        expect(parsed_paper_2_stub.occurrences.first).to eq(occurrence)
      end
    end

    context "figures" do
      it "outputs figures from a proceeding" do
        figure = {
          caption: "High-level Architecture of OpenBiodiv.",
          graphic: {
            href: "tdwgproceedings-01-e20084-g001.png", id: "oo_148450.png"
          },
          label: "Figure 1."
        }
        expect(parsed_proceedings_4_stub.figures.count).to eq(1)
        expect(parsed_proceedings_4_stub.figures.first).to eq(figure)
      end
      it "output figures from a paper" do
        caption = 'Palp of Longicoelotes geei sp. n., holotype male. '\
        'A Prolateral view B Ventral view C Retrolateral view. CAT = '\
        'anterior tip of conductor, CF = cymbial furrow, CO = conductor, '\
        'CPT = posterior tip of conductor, E = embolus, EB = embolic base, '\
        'MA = median apophysis, PA = patellar apophysis, ST = subtegulum, '\
        'T = tegulum, TS = tegular sclerite, VTA = ventral tibial apophysis. '\
        'Scale bar: equal for A, B, C.'
        figure = {
          caption: caption,
          graphic: {
            href: "zookeys-686-137-g001.jpg", id: "oo_146588.jpg"
          },
          label: "Figure 1."
        }
        expect(parsed_paper_stub.figures.count).to eq(6)
        expect(parsed_paper_stub.figures.first).to eq(figure)
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
        expect(refs[0][:authors].count).to eq(6)
        doi = "https://doi.org/10.1023/A:1011438729881"
        expect(refs[1][:doi]).to eq(doi)
      end
      it "output references from a paper" do
        refs = parsed_paper_stub.references
        expect(refs.count).to eq(10)
        cit = "World Spider Catalog. 2017. World Spider Catalog. http://wsc.nmbe.ch"
        expect(refs[7][:full_citation]).to eq(cit)

        cit = "Zhao, Z, S Li. 2016. Papiliocoelotes gen. n., a new genus of "\
              "Coelotinae (Araneae, Agelenidae) spiders from the Wuling "\
              "Mountains, China. ZooKeys 585: 33–50. "\
              "https://doi.org/10.3897/zookeys.585.8007"
        expect(refs[8][:full_citation]).to eq(cit)

      end
    end

  end

end
