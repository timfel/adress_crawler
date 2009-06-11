require 'ostruct'
require 'base64'
require 'curb'

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
	 #"PHOTO;VALUE=uri:"+n+"\n" 
      }
   }
end
