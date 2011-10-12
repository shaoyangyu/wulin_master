require 'wulin_master/engine' if defined?(Rails)

module WulinMaster
  # The folder name with files belongs to wulin_master under Rails app's app directory
  FOLDER_NAME = 'terra_nova'
  
  @javascripts = ['application']
  @stylesheets = ['application']

  def self.add_javascript(script)
    @javascripts << script
  end

  def self.add_stylesheet(css)
    @stylesheets << css
  end

  def self.javascripts
    @javascripts
  end

  def self.stylesheets
    @stylesheets
  end

  def self.default_datetime_format=(new_value)
    @default_datetime_format = new_value
  end

  def self.default_datetime_format
    @default_datetime_format || :db
  end

end

require 'wulin_master/configuration'
require 'wulin_master/actions'
require 'wulin_master/menu/menu'
require 'wulin_master/screen/screen'
require 'wulin_master/screen/grid_config'

WulinMaster::add_javascript 'master/master.js'
WulinMaster::add_stylesheet 'master.css'

Time::DATE_FORMATS[:no_seconds] = "%Y-%m-%d %H:%M"
Time::DATE_FORMATS[:date] = "%Y-%m-%d"
Time::DATE_FORMATS[:time] = "%H:%M"
WulinMaster.default_datetime_format = :no_seconds


