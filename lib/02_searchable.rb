require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    p where_line = params.keys.map {|key| "#{key} = ?"}.join(" AND ")
    p vals = params.values

    DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    .map {|cat| self.new(cat)}
  end
end

class SQLObject
  extend Searchable
end
