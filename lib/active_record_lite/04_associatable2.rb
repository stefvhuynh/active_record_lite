require_relative '03_associatable'

# Phase V
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      through_table   = through_options.table_name
      source_options  = through_options.model_class.assoc_options[source_name]
      source_table    = source_options.table_name

      query = DBConnection.execute(<<-SQL, send(through_options.foreign_key))
        SELECT #{source_table}.*
          FROM #{source_table}
          JOIN #{through_table}
               ON #{source_table}.#{source_options.primary_key} =
               #{through_table}.#{source_options.foreign_key}
         WHERE #{source_table}.#{source_options.primary_key} = ?
      SQL

      source_options.model_class.new(query.first)
    end
  end
end
