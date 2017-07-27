require "rspec"
require "taxpub"

module Helpers

  def parsed_stub
    tps = Taxpub.new
    tps.file_path = File.join(__dir__, "files", "tdwgproceedings.pensoft.net.xml")
    tps.parse
    tps
  end

end