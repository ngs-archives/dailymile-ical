require 'date'
require 'icalendar'
require 'json'
require 'net/http'
require 'rubygems'
require 'sinatra'

include Icalendar

configure do
  mime_type :ical, 'text/calendar'
  mime_type :plain, 'text/plain'
end

get '/' do
  content_type :plain
  'IT WORKS'
end

get '/robots.txt' do
  content_type :plain
  '# User-Agent: *'
end

get '/:username.ics' do
  content_type :ical
  cal = Calendar.new
  cal.timezone do
    timezone_id             "Japan/Tokyo"
    standard do
      timezone_offset_from  "+0900"
      timezone_offset_to    "+0900"
      timezone_name         "JST"
    end
  end
  username = params['username']
  add_events(cal, username, 1)
  add_events(cal, username, 2)
  add_events(cal, username, 3)
  cal.to_ical
end

def add_events cal, username, page = 1
  url = "http://api.dailymile.com/people/#{username}/entries.json?page=#{page}"
  res = Net::HTTP.get_response(URI.parse(url))
  data = JSON.parse(res.body)
  data['entries'].each do |entry|
    wo = entry['workout']
    dist = wo['distance']
    e = DateTime.parse(entry['at'])
    s = e - Rational(wo['duration']  ,24*60*60)
    verb = 'Moved'
    case wo['activity_type']
    when 'Cycling'
      verb = 'Rode'
    when 'Runnning'
      verb = 'Ran'
    end
    cal.event do
      dtstart      s
      dtend        e
      summary     "#{wo['title']} #{verb} #{dist['value']} #{dist['units']} felt #{wo['felt']}"
      description "#{entry['message']} #{entry['url']}"
      klass       'PUBLIC'
    end
  end
end

