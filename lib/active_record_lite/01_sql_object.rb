require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
    # Grabs the column names and maps them to symbols.
    DBConnection.execute2(<<-SQL).first.map(&:to_sym)
      SELECT *
        FROM #{table_name}
    SQL
  end

  def self.finalize!
    columns.each do |column|
      # Inside Module#define_method, the scope is the instance of the
      # class, so the attributes method refers to the instance method.
      define_method(column) { attributes[column] }
      define_method("#{column}=") { |arg| attributes[column] = arg }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    query = DBConnection.execute(<<-SQL)
      SELECT *
        FROM #{table_name}
    SQL

    parse_all(query)
  end

  def self.parse_all(results)
    results.each_with_object([]) do |record, objects|
      objects << self.new(record)
    end
  end

  def self.find(id)
    query = DBConnection.execute(<<-SQL, id)
      SELECT *
        FROM #{table_name}
       WHERE id = ?
    SQL

    parse_all(query).first
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    # keys = attributes.keys.join(", ")
    # question_marks = (["?"] * attributes.length).join(", ")

    col_names = self.class.columns
    keys = col_names.join(", ")
    question_marks = (["?"] * col_names.length).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO #{self.class.table_name} (#{keys})
           VALUES (#{question_marks})
    SQL

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    columns = self.class.columns

    params.keys.each do |key|
      if columns.include?(key.to_sym)
        # The setter for key is defined in SQLObject::finalize!.
        send("#{key}=", params[key])
      else
        raise "unknown attribute '#{key}'"
      end
    end
  end

  def save
    id.nil? ? insert : update
  end

  def update
    # keys = attributes.keys.join(" = ?, ") + " = ?"
    keys = self.class.columns.join(" = ?, ") + " = ?"

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE #{self.class.table_name}
         SET #{keys}
       WHERE id = ?
    SQL
  end

  def attribute_values
    # attributes.values
    self.class.columns.map { |column| send(column) }
  end
end
