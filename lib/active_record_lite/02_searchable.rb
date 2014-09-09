require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    keys = params.keys.join(" = ? AND ") + " = ?"

    query = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
        FROM #{table_name}
       WHERE #{keys}
    SQL

    parse_all(query)
  end
end

class SQLObject
  extend Searchable
end
