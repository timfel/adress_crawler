require 'ostruct'
require 'base64'
require 'curb'

# This is a very simple implementation to 
# create vCards. Details are simply added 
# directly through the OpenStruct interface.
# On exporting the vCard, for each mapping 
# that exists in the class-dictionary the 
# named property in the OpenStruct is checked 
# and a formatted output hopefully adhering to 
# the vCard standard V3 is generated 
class VCard < OpenStruct
  def export filename
    filename += ".vcf"
    File.open(filename, 'a') do |f|
      f << "BEGIN:VCARD\nVERSION:3.0\n"
      @@mapping.each do |field,lambda|
        if respond_to? field
          f << @@mapping[field].call(self.send(field))
        end
      end
      f << "END:VCARD\n"
    end
  end

  @@mapping = {
    :name => lambda { |n| 
      s = n.split
      "N:"+s[1..-1].join(" ")+";"+s.first+";;;\n"+"FN:"+n+"\n" },
    :phone => lambda { |n|
      "TEL:"+n+"\n" },
    :birthday => lambda { |n|
      "BDAY;value=date:"+n.split(".").reverse.join+"\n" },
    :image => lambda { |n|
      img = Base64.encode64(Curl::Easy.perform(n).body_str).gsub(/\s+/s, "\n   ")
      "PHOTO;BASE64:\n   " + img.gsub(/   $/, "")
    }
  }
end
