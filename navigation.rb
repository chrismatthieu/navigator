# Weather app = https://raw.github.com/voxeo/tropo-samples/861d5277876eabeab8db69dfc413b195d247366e/ruby/weatherforecast.rb

#Yahoo API
#Application ID: Ih0SP672
#Consumer Key: dj0yJmk9WXNXVXBUT3B1NzhNJmQ9WVdrOVNXZ3dVMUEyTnpJbWNHbzlNVFE0TVRVNU5UWXkmcz1jb25zdW1lcnNlY3JldCZ4PTkx
#Consumer Secret: 872cbfdb535e402fa5a0be208048a8f93f935bf8

#WeatherBug


require 'rexml/document'
require 'open-uri'
 
DAYS = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
 
## Helper Classes
class ReverseLookup
  attr_accessor :npa, :nxx, :provider, :url, :city, :state
  
  TELCODATA_URL = "http://www.telcodata.us/query/queryexchangexml.html?"
  
  def initialize(number)
    @npa = number.to_s[0,3]
    @nxx = number.to_s[3,3]
    
    @url = TELCODATA_URL + "npa=#{@npa}&nxx=#{@nxx}"
    
    lookup
  end
  
  def lookup
    @doc = REXML::Document.new(open(@url))
    
    @city = @doc.elements['root/exchangedata/ratecenter'].text
    @state = @doc.elements['root/exchangedata/state'].text
    
    log "Reverse Lookup Results: #{@city}, #{@state}"
  end
end
 
 
 
class Geocoder
  attr_reader :longitude, :latitude, :country
  
  APP_ID = 'Ih0SP672' # Get yours at http://developer.yahoo.com/maps/rest/V1/geocode.html
  BASE_URL = "http://local.yahooapis.com/MapsService/V1/geocode?appid=#{APP_ID}&"
  
  def initialize(location)
    @url = BASE_URL + "location=#{location}&"
    @url.gsub!(/ /, '%20')
    
    geocode
  end
  
  def geocode
    @doc = REXML::Document.new(open(@url))
    
    @latitude = @doc.elements['ResultSet/Result/Latitude'].text
    @longitude = @doc.elements['ResultSet/Result/Longitude'].text
    @country = @doc.elements['ResultSet/Result/Country'].text
    
    log "Geocoder Results: latitude => #{@latitude}, longitude => #{@longitude}"
  end
end
 
 
 
module Weather
  A_CODE = 'A7457998574' # Get yours at http://weather.weatherbug.com/desktop-weather/api.html
  
  class Forecast
    attr_reader :city, :country, :days
 
    BASE_URL = "http://api.wxbug.net/getForecastRSS.aspx?ACode=#{A_CODE}&OutputType=1&"
  
    def initialize(latitude, longitude, country = 'US')
      unit_type = country == 'US' ? 'UnitType=0&' : 'UnitType=1&' # imperial or metric
      @url = BASE_URL + unit_type + "lat=#{latitude}&long=#{longitude}&"
      @days = {}
      
      get
    end
  
    def get
      @doc = REXML::Document.new(open(@url))
    
      @city = @doc.elements['aws:weather/aws:forecasts/aws:location/aws:city'].text
      @country = @doc.elements['aws:weather/aws:forecasts/aws:location/aws:country'].text rescue 'USA'
    
      @doc.elements.each('aws:weather/aws:forecasts/aws:forecast') do |forecast|
        @days[forecast.elements['aws:title'].text] = {
          :condition => forecast.elements['aws:short-prediction'].text,
          :prediction => forecast.elements['aws:prediction'].text.gsub(/^ /, '').gsub(/\&deg\;(C|F)?/, ' degrees'),
          :high => forecast.elements['aws:high'].text.to_i,
          :low => forecast.elements['aws:low'].text.to_i
        }
      end
      
      @days.each_with_index do |forecast, i|
        day = forecast[0] # hash key
        forecast = forecast[1] # hash
        
        forecast[:prediction].gsub!(/( |[ESW])N( |\.|[NESW])/, '\1 north \2')
        forecast[:prediction].gsub!(/( |[NSW])E( |\.|[NESW])/, '\1 east \2')
        forecast[:prediction].gsub!(/( |[NEW])S( |\.|[NESW])/, '\1 south \2')
        forecast[:prediction].gsub!(/( |[NSE])W( |\.|[NESW])/, '\1 west \2')
        forecast[:prediction].gsub!(/mph/, 'miles per hour')
        
        forecast[:text] = "#{day}, #{forecast[:prediction]} Low of #{forecast[:low]} degrees."
      end
 
    end
    
    def from(weekday)
      forecasts = []
      (0..6).each do |n|
        day_index = DAYS.index(weekday) + n
        day_index = day_index - 7 if day_index > 6
        
        forecasts << @days[DAYS[day_index]][:text]
        
        break if Time.now.wday == day_index + 1
      end
      
      return forecasts.join(' ')
    end
    
    def read(day = DAYS[Time.now.wday])
      prompt_options = { :beep => false,
                         :choices => DAYS.join(", "),
                         :timeout => 2,
                         :onEvent => lambda { |event|
                           case event.name.to_sym
                           when :choice
                             read event.value
                           when :badChoice
                             say "I'm sorry, I didn't understand what you said"
                           end
                         }
                       }
      prompt from(day), prompt_options
    end
  end
end


# Set the voice and geo data used throughout the demo
myvoice = "Kate"
myzipcode = "85044"
gmtoffset = -7
long = "0"
lat = "0"

def isNumeric(s)
    Float(s) != nil rescue false
end

#Could add callerID lookup and/or set name
if isNumeric($currentCall.callerName)
  if $currentCall.callerID == "4803194368"
    caller = "chris"
  else 
    caller = "joe"
  end
else
  caller = $currentCall.callerName
end 

say "Hello " + caller, {:voice => myvoice}

loop do 

result = ask "How may I help you?  Choose from directions, weather, music, news feeds, twitter, time, or goodbye .", {
  :voice => myvoice,
  :choices => "directions, weather, music, news feeds, twitter, time, goodbye",
  :timeout => 100.0,
  :attempts => 3}

if result.value == 'directions'

result = ask "Where would you like to go?", {
  :voice => myvoice,
  :choices => "airport, star bucks, gas station",
  :timeout => 10.0,
  :attempts => 3}

if result.value == 'airport'
  say "You chose " + result.value, {:voice => myvoice}
elsif result.value == 'star bucks'
  say "You chose " + result.value, {:voice => myvoice}
elsif result.value == 'gas station'
  say "You chose " + result.value, {:voice => myvoice}
end

elsif result.value == 'weather'

reverse = ReverseLookup.new($currentCall.callerID) #('4803194368') 
geocoder = Geocoder.new("#{reverse.city}, #{reverse.state}")
forecast = Weather::Forecast.new(geocoder.latitude, geocoder.longitude, geocoder.country)
 
 
zip_prompt_options = { :beep => false,
                       :choices => '[5 DIGITS], [6 DIGITS]',
                       :timeout => 2,
                       :voice => myvoice,
                       :onEvent => lambda { |event|
                         case event.name.to_sym
                         when :choice
                           if event.value.length == 6
                             reverse = ReverseLookup.new(event.value)
                             geocoder = Geocoder.new("#{reverse.city}, #{reverse.state}")
                           else
                             geocoder = Geocoder.new(event.value)
                           end
                           forecast = Weather::Forecast.new(geocoder.latitude, geocoder.longitude, geocoder.country)
                           say "Here is the weather for #{forecast.city}", {:voice => myvoice}
                         when :badChoice
                           say "I'm sorry, I didn't understand what you said", {:voice => myvoice}
                         end } }
 
prompt "I have the weather forecast for #{forecast.city}, say a zip code or area code and prefix if you want a different city.", zip_prompt_options
say "You may skip by saying a day at any time.", {:voice => myvoice}
forecast.read
say "This concludes the weather forecast for #{forecast.city}", {:voice => myvoice}


elsif result.value == 'music'
  say "You chose " + result.value, {:voice => myvoice}
elsif result.value == 'news feeds'
  say "You chose " + result.value, {:voice => myvoice}
elsif result.value == 'twitter'
  say "You chose " + result.value, {:voice => myvoice}
elsif result.value == 'time'

  time = Time.new.local + gmtoffset
  say "The current time is " + time.strftime("%H:%M:%S %A %B %d "), {:voice => myvoice}

elsif result.value == 'goodbye'
  say "Glad to be of service. Drive safely.", {:voice => myvoice}
  break
end

end #loop