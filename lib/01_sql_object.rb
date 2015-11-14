require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    .first.map(&:to_sym)

  end

  def self.finalize!
    columns.each do |column|
      define_method "#{column}" do
        attributes[:"#{column}"]
      end

      define_method "#{column}=" do |val|
        attributes[:"#{column}"] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    parse_all (
    DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    )
  end

  def self.parse_all(results)
    results.map do |attrs|
      self.new(attrs)
    end

  end

  def self.find(id)
    parse_all(
    DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    ).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless
      self.class.columns.include?(:"#{attr_name}")

      self.send :"#{attr_name}=", value
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |col|
      self.send(col)
    end
  end

  def insert
    col_names =  self.class.columns.join(", ")
    q_marks = (["?"] * self.class.columns.length).join(", ")
    DBConnection.execute(<<-SQL, *self.attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{q_marks})
    SQL

    self.send(:id=, DBConnection.last_insert_row_id)
  end

  def update
    set_line = self.class.columns.map {|col| "#{col} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *self.attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
