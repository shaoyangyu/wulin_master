module WulinMaster
  class Menu < Array
  
    # Rendering
    # ----------
    def view_path
      File.join(File.dirname(__FILE__), '..', '..', '..', 'app', 'views')
    end
  
    # Satisfy render_to_string
    def action_name
      ""
    end
  
    # Render the menu
    def render
      ActionView::Base.new(view_path).render(:partial => "/menu", :locals => {:menu => self})
    end
  end

  class MenuEntry
    attr_reader :title, :path, :options
  
    def initialize(title, path, options)
      @title = title
      @path = path
      @options = options
    end
  
    def is_submenu?
      false
    end
    
    def is_hidden?
      @options[:hidden]
    end

    def active_paths
      return nil if options[:active_paths].blank?
      paths = options.delete(:active_paths)
      Array === paths ? paths.join(',') : paths
    end
  end

  class SubMenu < Menu
    attr_reader :title
  
    def initialize(title)
      @title = title
    end

    def is_submenu?
      true
    end
  end
end