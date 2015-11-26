require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.underscore + 's'
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    options[:foreign_key] ? @foreign_key = options[:foreign_key] : @foreign_key = :"#{name}_id"
    options[:primary_key] ? @primary_key = options[:primary_key] : @primary_key = :id
    options[:class_name] ? @class_name = options[:class_name] : @class_name = "#{name.to_s.camelcase}"
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    options[:foreign_key] ? @foreign_key = options[:foreign_key] : @foreign_key = :"#{self_class_name.downcase}_id"
    options[:primary_key] ? @primary_key = options[:primary_key] : @primary_key = :id
    options[:class_name] ? @class_name = options[:class_name] : @class_name = "#{name.to_s.camelcase.singularize}"
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method name do
      foreign_key_value = self.send(options.foreign_key)
      class_name = options.model_class
      class_name.where(options.primary_key => foreign_key_value).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method name do
      primary_key_value = self.send(options.primary_key)
      class_name = options.model_class
      objs = class_name.where(options.foreign_key => primary_key_value)
      # debugger
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
