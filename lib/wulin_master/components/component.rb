require 'wulin_master/components/component_styling'

module WulinMaster
  class Component
    include ComponentStyling

    attr_accessor :params, :screen, :controller, :custom_config

    # apply a config, dispatch it to a config pool (like option_pool, styles_pool etc) 
    def self.apply_config(key, value, params={})
      if self.respond_to?(key) and (arguments_count = self.method(key).arity) != 0    # if component class respond to the config method and it is a writter method
        if arguments_count == 1
          self.send(key, value)
        elsif arguments_count == -1 or arguments_count == -2  # if this method accept options, pass the grid's params as options
          # when argument_count is -1, sometimes it can accept self.params (like :fill_window), sometimes it can't (like :title)
          begin
            self.send(key, value, params)
          rescue 
            self.send(key, value)
          end
        end
      end
    end

    def initialize(screen_instance=nil, config={})
      @screen = screen_instance
      @params = screen_instance.try(:params)
      @controller = screen_instance.try(:controller)
      @custom_config = config
    end

    def is_panel?
      false
    end

    def is_grid?
      false
    end
  end
end