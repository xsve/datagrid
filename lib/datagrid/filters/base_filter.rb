class Datagrid::FilteringError < StandardError
end

class Datagrid::Filters::BaseFilter

  attr_accessor :grid_class, :options, :block, :name

  def initialize(grid_class, name, options = {}, &block)
    self.grid_class = grid_class
    self.name = name
    self.options = options
    self.block = block || default_filter_block
  end

  def parse(value)
    raise NotImplementedError, "#parse(value) suppose to be overwritten"
  end

  def apply(grid_object, scope, value)
    if value.nil?
      return scope if !allow_nil?
    else
      return scope if value.blank? && !allow_blank?
    end

    result = execute(value, scope, grid_object, &block)
    return scope unless result
    unless grid_object.driver.match?(result)
      raise Datagrid::FilteringError, "Can not apply #{name.inspect} filter: result #{result.inspect} no longer match #{grid_object.driver.class}."
    end
    result
  end

  def parse_values(value)
    if !self.multiple && value.is_a?(Array)
      raise Datagrid::ArgumentError, "#{grid_class}##{name} filter can not accept Array argument. Use :multiple option."
    end
    values = Array.wrap(value)
    values.map! do |v|
      self.parse(v)
    end
    self.multiple ? values : values.first
  end

  def header
    options[:header] ||
      I18n.translate(self.name, :scope => "datagrid.#{grid_class.param_name}.filters", :default => self.name.to_s.humanize)
  end

  def default
    default = self.options[:default]
    default.respond_to?(:call) ? default.call : default
  end

  def multiple
    self.options[:multiple]
  end

  def allow_nil?
    options.has_key?(:allow_nil) ? options[:allow_nil] : options[:allow_blank]
  end

  def allow_blank?
    options[:allow_blank]
  end

  def form_builder_helper_name
    self.class.form_builder_helper_name
  end

  def self.form_builder_helper_name
    :"datagrid_#{self.to_s.demodulize.underscore}"
  end

  def default_filter_block
    filter = self
    lambda do |value, scope, grid|
      filter.dummy? ? nil : filter.default_filter(value, scope, grid)
    end
  end

  def default_filter(value, scope, grid)
    driver = grid.driver
    if !driver.has_column?(scope, name) && driver.to_scope(scope).respond_to?(name)
      driver.to_scope(scope).send(name, value)
    else
      default_filter_where(driver, scope, value)
    end
  end

  def format(value)
    value.nil? ? nil : value.to_s
  end
  
  def dummy?
    options[:dummy]
  end

  protected

  def default_filter_where(driver, scope, value)
    driver.where(scope, name, value)
  end

  def execute(value, scope, grid_object, &block)
    if block.arity == 1
      scope.instance_exec(value, &block)
    else
      Datagrid::Utils.apply_args(value, scope, grid_object, &block)
    end
  end

end

