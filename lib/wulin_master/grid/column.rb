module WulinMaster
  class Column
    attr_accessor :name, :options

    def initialize(name, grid_class, opts={})
      @name = name
      @grid_class = grid_class
      @options = {:width => 150, :sortable => true, :editable => true}.merge(opts)
    end

    def label
      @options[:label] || @name.to_s.underscore.humanize
    end

    def datetime_format
      @options[:datetime_format] || WulinMaster.default_datetime_format
    end

    def to_column_model
      field_name = @name.to_s
      sort_col_name = self.reflection ? self.option_text_attribute : @name.to_s
      table_name = self.reflection ? self.reflection.klass.table_name.to_s : self.model.table_name.to_s
      new_options = @options.dup
      @options.each {|k,v| new_options.merge!(k => v.call) if v.class == Proc }
      h = {:id => @name, :name => self.label, :table => table_name, :field => field_name, :type => sql_type, :sortColumn => sort_col_name}.merge(new_options)
      h.merge!(reflection_options) if reflection
      h
    end

    # Format a value 
    # Called during json rendering
    def format(value)
      if value.class == Time || value.class == ActiveSupport::TimeWithZone
        value.to_formatted_s(datetime_format)
      elsif value.class.name == 'BSON::ObjectId'
        value.to_s
      else
        value
      end
    end

    # Apply a where condition on the query to filter the result set with the filtering value
    def apply_filter(query, filtering_value)
      return query if filtering_value.blank?
      if self.reflection
        table_name = options[:join_aliased_as] || self.reflection.klass.table_name
        return query.where(["UPPER(#{table_name}.#{self.option_text_attribute}) LIKE UPPER(?)", filtering_value+"%"])
      else
        case sql_type.to_s
        when "datetime"
          return query.where(["to_char(#{self.name}, 'YYYY-MM-DD') LIKE UPPER(?)", filtering_value+"%"])
        else
          filtering_value = filtering_value.gsub(/'/, "''")
          if self.model.columns.map(&:name).map(&:to_s).include?(self.name)
            complete_column_name = "#{model.table_name}.#{self.name}"
          else
            complete_column_name = self.name
          end
          if model < ActiveRecord::Base
            return query.where(["UPPER(#{complete_column_name}) LIKE UPPER(?)", filtering_value+"%"])
          else
            if options[:type] == 'Datetime' and format_datetime(filtering_value).present? # Datetime filter for Mongodb
              return query.where(
              self.name.to_sym.gte => format_datetime(filtering_value)[:from], 
              self.name.to_sym.lte => format_datetime(filtering_value)[:to]
              )
            else
              return query.where(self.name => Regexp.new("#{Regexp.escape(filtering_value)}.*", true))
            end
          end
        end
      end
    end

    def apply_order(query, direction)
      return query unless ["ASC", "DESC"].include?(direction)
      if self.reflection
        table_name = options[:join_aliased_as] || self.reflection.klass.table_name
        query.order("#{table_name}.#{self.option_text_attribute} #{direction}")
      else
        query.order("#{@name} #{direction}")
      end
    end

    def model
      @grid_class.model
    end

    # Function name isn't good
    def sql_type
      return :unknown if self.model.blank?
      column = (self.model.respond_to?(:all_columns) ? self.model.all_columns : self.model.columns).find {|col| col.name.to_s == self.name.to_s}
      (column.try(:type) || association_type || :unknown).to_s.to_sym
    end

    def reflection
      @reflection ||= self.model.reflections[@name.to_sym]
    end

    def choices
      @choices ||= (self.reflection ? self.reflection.klass.all : [])
    end

    def reflection_options
      {:choices => (@options[:choices].present? ? @options[:choices].to_json : nil) || self.choices.collect{|k| {:id => k.id, option_text_attribute => k.send(option_text_attribute)}},
      :optionTextAttribute => self.option_text_attribute}
    end

    def foreign_key
      self.reflection.try(:foreign_key)
    end

    def form_name
      self.reflection ? self.foreign_key : self.name
    end

    # Returns the sql names used to generate the select
    def sql_names
      if self.reflection.nil?
        [self.model.table_name+"."+name.to_s]
      else
        [self.model.table_name+"."+self.reflection.foreign_key.to_s, self.reflection.klass.table_name+"."+option_text_attribute.to_s]
      end
    end

    def presence_required?
      self.model.validators.find{|validator| validator.class == ActiveModel::Validations::PresenceValidator &&validator.attributes.include?(@name.to_sym)}
    end

    # Returns the´includes to add to the query 
    def includes
      if self.reflection
        [@name.to_sym]
      else
        []
      end
    end

    # Returns the´joins to add to the query
    def joins
      if self.reflection && presence_required?
        [@name.to_sym]
      else
        []
      end
    end

    # Returns the json for the object in argument
    def json(object)
      if association_type.to_s == 'belongs_to'
        {:id => object.send(self.reflection.foreign_key.to_s), option_text_attribute => object.send(self.name.to_sym).try(:send,option_text_attribute).to_s}
      elsif association_type.to_s == 'has_and_belongs_to_many'
        ids = object.send("#{self.reflection.klass.name.underscore}_ids")
        op_attribute = object.send(self.reflection.name.to_s).map{|x| x.send(option_text_attribute)}.join(',')
        {id: ids, option_text_attribute => op_attribute}
      else
        self.format(object.send(self.name.to_s))
      end
    end

    # For belongs_to association, the name of the attribute to display
    def option_text_attribute
      @options[:option_text_attribute] || :name
    end

    # == Generate the datetime rang filter for mongodb
    # === Date part 
    # TODO: Finish the time part
    def format_datetime(datetime)
      if datetime =~ /^\d{1,4}-?$/ # 20 2011 2011-
        year = datetime.first(4)
        from_year = year.size <=3 ? (year + '0' * (4 - 1 - year.size) + '1') : year
        to_year = year + '9' * (4 - year.size)
        { from: build_datetime(from_year.to_i), to: build_datetime(to_year.to_i, 12, 31, 23, 59, 59) } # 2011-01-01 - 2011-12-31  2001-01-01 - 2099-12-31
      elsif datetime =~ /^\d{1,4}-[0-1]$/ # 2011-0 - 2011-1
        year, month = datetime.split('-').map(&:to_i)
        if month == 0
          { from: build_datetime(year), to: build_datetime(year, 9, 30, 23, 59, 59) } # 2011-01-01 - 2011-09-31
        elsif month == 1
          { from: build_datetime(year, 10), to: build_datetime(year, 12, 31, 23, 59, 59) } # 2011-10-01 - 2011-12-31
        end
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-1])-?$/ # 2011-01 - 2011-09  or  2011-10 - 2011-11
        year, month = datetime.first(7).split('-').map(&:to_i)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month), to: build_datetime(year, month, 31, 23, 59, 59) } # 2011-01-01 - 2011-01-31
        else
          { from: build_datetime(year, month), to: build_datetime(year, month, 30, 23, 59, 59) } # 2011-02-01 - 2011-02-30
        end
      elsif datetime =~ /^\d{1,4}-12-?$/ # 2011-12
        year = datetime.first(4).to_i
        { from: build_datetime(year, 12), to: build_datetime(year, 12, 31, 23, 59, 59) } # 2011-12-01 - 2011-12-31
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-0$/ # 2011-12-0
        year, month, date = datetime.split('-').map(&:to_i)
        { from: build_datetime(year, month, 1), to: build_datetime(year, month, 9, 23, 59, 59)} # 2011-12-01 - 2011-12-09
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-[1-2]$/ # 2011-12-1 2011-12-2
        year, month, date = datetime.split('-').map(&:to_i)
        { from: build_datetime(year, month, date * 10), to: build_datetime(year, month, (date * 10) + 9, 23, 59, 59) } # 2011-12-01 - 2011-12-09
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-[3]$/ # 2011-12-3
        year, month, date = datetime.split('-').map(&:to_i)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 31, 23, 59, 59) } # 2011-12-30 - 2011-12-31
        else
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 30, 23, 59, 59) } # 2011-12-30 - 2011-12-30
        end
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-3[0-1]\s?$/ # 2011-12-31  2011-11-30
        year, month, date = datetime.split('-').map(&:to_i)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month, date), to: build_datetime(year, month, date, 23, 59, 59) } # 2011-12-30 - 2011-12-31
        elsif date == 30
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 30, 23, 59, 59) } # 2011-12-30 - 2011-12-30
        end
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s?$/ # 2011-12-01 - 2011-12-29
        year, month, date = datetime.split('-').map(&:to_i)
        { from: build_datetime(year, month, date), to: build_datetime(year, month, date, 23, 59, 59) } # 2011-11-11 00:00:00 - 2011-11-11 23:59:59
      else
        {}
      end
    end

    def build_datetime(*args)
      DateTime.new(*args) rescue nil
    end

    private

    def association_type
      self.reflection.try(:macro)
    end
  end
end
