require 'ostruct'

class VCard < OpenStruct
   def export filename
      filename += ".vCard"
      File.open(filename, 'w') do |f|
	 f << "BEGIN:VCARD\nVERSION:3.0\n"
	 @@mapping.each do |name,lambda|
	    if respond_to? name 
	       f << @@mapping[name].call(self.send(name)) << "\n"
	    end
	 end
	 f << "END:VCARD"
      end
   end

   @@mapping = {
      :name => lambda { |n| 
         s = n.split
         "N:"+s[1..-1].join(" ")+";"+s.first },
      :phone => lambda { |n|
	 "TEL:"+n },
      :birthday => lambda { |n|
	 "BDAY:"+n.split(".").reverse.join
      }
   }
end
