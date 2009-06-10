#!/usr/bin/env ruby1.9
require 'mechanize'
require 'vcard'

class StudiCrawler
    def initialize mail,pw
	@agent = WWW::Mechanize.new
	@page = @agent.get 'https://secure.studivz.net/Login'
	login mail,pw
    end

    def login mail,pw
       forms = @page.forms.first
       forms.email=mail
       forms.password=pw
       @page = forms.click_button
    end

    def goto goto_dict
       unless goto_dict[:uri].nil?
	  uri = goto_dict[:uri]
	  uri = @page.uri+uri unless uri.to_s =~ /^http/u
	  @page = @agent.get uri
       end
       @page = @agent.get @page.uri+friends[goto_dict[:name].to_sym].uri unless goto_dict[:name].nil?
       @page
    end

    def friends
       crawl_friends if @friends.nil?
       @friends
    end

    def friend name
       @friends[name.to_sym]
    end

    [:image, :birthday].each do |item|
       define_method(item) do |name|
	  f = friend(name)
	  if f.send(item).nil?
	     curpage = @page
	     unless @page.uri.to_s =~ Regexp.new(f.uri.to_s+"$")
		goto :uri => f.uri
	     end
	     send(("get_"+item.to_s).to_sym, f)
	     @page = curpage
	  end
	  f.send(item)
       end
    end

    def get_friends
       @friends ||= {}
       afterIdx = @page.links.index(@page.link_with(:text => 'Alle Freunde'))
       curfriends = @page.links[afterIdx+1..-3].select do |l| 
	  @page.links[@page.links.index(l)+2].text.include? 'Freunde'
       end
       curfriends.each do |item|
	  @friends[item.text.to_sym] = VCard.new
	  @friends[item.text.to_sym].uri = item.uri
	  @friends[item.text.to_sym].name = item.text
       end
       @friends
    end

    def get_birthday friend
       page = @page.link_with(:text => /^[0-9][0-9]\.[0-9][0-9]\.[1-9][0-9][0-9][0-9]$/u)
       friend.birthday = page.text unless page.nil?
    end

    def get_image friend
       img = @page.search("#profileImage")
       unless img.nil?
	  img.to_a.compact! 
	  unless img.first.nil?
	     friend.image = img.first.attributes['src'] 
	  end
       end
    end

    def get_next_symbol
       @page.links.select do |l| 
	  begin
	     l.uri.to_s =~ /\/p\/2$/u
	  rescue URI::InvalidURIError
	  end
       end.compact.last.text
    end

    def fill_details
       get_friends.each do |name,values|
	  oldpage = @page
	  goto :uri => values.uri
	  birthday name
	  image name
	  print "."
	  @page = oldpage
       end
    end

    def crawl_friends
       oldpage = @page
       # make sure we're on the friends list
       goto :uri => @page.link_with(:text => 'Meine Freunde').uri
       next_page_sym = get_next_symbol
       fill_details
       #while !@page.link_with(:text => next_page_sym).nil?
	#  puts "Next page!"
	#  goto :uri => @page.link_with(:text => next_page_sym).uri
	#  fill_details
       #end 
       @page = oldpage
    end

    def export_friends
       friends.each do |name,vCard|
	  vCard.export(name.to_s.gsub(" ", "_"))
       end
    end
end


