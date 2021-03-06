require "action_view"

module Datagrid
  module FormBuilder

    def datagrid_filter(filter_or_attribute, options = {})
      filter = datagrid_get_filter(filter_or_attribute)
      options = Datagrid::Utils.add_html_classes(options, filter.name, datagrid_filter_html_class(filter))
      self.send(filter.form_builder_helper_name, filter, options)
    end

    def datagrid_label(filter_or_attribute, options = {})
      filter = datagrid_get_filter(filter_or_attribute)
      self.label(filter.name, filter.header, options)
    end

    protected
    def datagrid_boolean_enum_filter(attribute_or_filter, options = {})
      datagrid_enum_filter(attribute_or_filter, options)
    end

    def datagrid_boolean_filter(attribute_or_filter, options = {})
      check_box(datagrid_get_attribute(attribute_or_filter), options)
    end

    def datagrid_date_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:date, attribute_or_filter, options)
    end

    def datagrid_default_filter(attribute_or_filter, options = {})
      text_field datagrid_get_attribute(attribute_or_filter), options
    end

    def datagrid_enum_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if !options.has_key?(:multiple) && filter.multiple
        options[:multiple] = true
      end
      select filter.name, filter.select(object) || [], {:include_blank => filter.include_blank, :prompt => filter.prompt, :include_hidden => false}, options
    end

    def datagrid_integer_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.multiple && self.object[filter.name].blank?
        options[:value] = ""
      end
      datagrid_range_filter(:integer, filter, options)
    end

    def datagrid_range_filter(type, attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.range?
        options = options.merge(:multiple => true)


        from_options = datagrid_range_filter_options(object, filter, :from, options)
        to_options = datagrid_range_filter_options(object, filter, :to, options) 
        # 2 inputs: "from date" and "to date" to specify a range
        [
          text_field(filter.name, from_options),
          I18n.t("datagrid.misc.#{type}_range_separator", :default => "<span class=\"separator #{type}\"> - </span>"),
          text_field(filter.name, to_options)
        ].join.html_safe
      else
        text_field(filter.name, options)
      end
    end


    def datagrid_range_filter_options(object, filter, type, options)
      type_method_map = {:from => :first, :to => :last}
      options = Datagrid::Utils.add_html_classes(options, type)
      options[:value] = filter.format(object[filter.name].try(type_method_map[type]))
      # In case of datagrid ranged filter 
      # from and to input will have same id
      options[:id] = if !options.key?(:id) 
         # Rails provides it's own default id for all inputs
         # In order to prevent that we assign no id by default 
        options[:id] = nil
      elsif options[:id].present?
        # If the id was given we prefix it
        # with from_ and to_ accordingly
        options[:id] = [type, options[:id]].join("_")
      end
      options
    end

    def datagrid_string_filter(attribute_or_filter, options = {})
      datagrid_default_filter(attribute_or_filter, options)
    end

    def datagrid_float_filter(attribute_or_filter, options = {})
      datagrid_default_filter(attribute_or_filter, options)
    end

    def datagrid_get_attribute(attribute_or_filter)
      Utils.string_like?(attribute_or_filter) ?  attribute_or_filter : attribute_or_filter.name
    end

    def datagrid_get_filter(attribute_or_filter)
      if Utils.string_like?(attribute_or_filter)
        object.class.filter_by_name(attribute_or_filter) ||
          raise(Error, "Datagrid filter #{attribute_or_filter} not found")
      else
        attribute_or_filter
      end
    end

    def datagrid_filter_html_class(filter)
      filter.class.to_s.demodulize.underscore
    end

    class Error < StandardError
    end
  end
end


