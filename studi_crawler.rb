#!/usr/bin/env ruby1.9
require 'mechanize'
require 'vcard'

class StudiCrawler

  attr_accessor :login_url
  @login_url = 'https://secure.studivz.net/Login'

  def initialize mail,pw
    @agent = WWW::Mechanize.new
    @page = @agent.get login_url
    login mail,pw
  end

  # tries to fill in the forms and login
  def login mail,pw
    forms = @page.forms.first
    forms.email=mail
    forms.password=pw
    @page = forms.click_button
  end

  # Goes to a page
  # This can be either a full url, a sub-url 
  # (which is then appended) or a friends name,
  # for which an initial url-lookup is done 
  def goto newPage
    unless friends[newPage.to_sym].nil?
      uri = friends[newPage.to_sym].uri
    end
    uri ||= newPage
    uri = @page.uri+uri unless uri.to_s =~ /^http/u
    @page = @agent.get uri
    @page
  end

  # lazy accessor
  def friends
    crawl_friends if @friends.nil?
    @friends
  end

  def friend name
    @friends[name.to_sym]
  end

  # Accessing details. Lazily tries to 
  # retrieve them using the get_DETAIL method
  [:image, :birthday].each do |item|
    define_method(item) do |name|
      f = friend(name)
      if f.send(item).nil?
        curpage = @page
        unless @page.uri.to_s =~ Regexp.new(f.uri.to_s+"$")
          goto f.uri
        end
        send(("get_"+item.to_s).to_sym, f)
        @page = curpage
      end
      f.send(item)
    end
  end

  def get_friends
    @friends ||= {}

    #+TODO : refactor this out!
    afterIdx = @page.links.index(@page.link_with(:text => 'Alle Freunde'))
    curfriends = @page.links[afterIdx+1..-3].select do |l| 
      ((@page.links[@page.links.index(l)+2].text.include? 'Freunde') and (l.uri.to_s =~ /\/Profile\//))
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
      goto values.uri
      birthday name
      image name
      print "."
      @page = oldpage
    end
  end

  def crawl_friends
    oldpage = @page
    # make sure we're on the friends list
    goto @page.link_with(:text => 'Meine Freunde').uri
    next_page_sym = get_next_symbol
    fill_details
    while !@page.link_with(:text => next_page_sym).nil?
      puts "Next page!"
      goto @page.link_with(:text => next_page_sym).uri
      fill_details
    end 
    @page = oldpage
  end

  def export_friends filename
    friends.each do |name,vCard|
      vCard.export(filename)
    end
  end
end


