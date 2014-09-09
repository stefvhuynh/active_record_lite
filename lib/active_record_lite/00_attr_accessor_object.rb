class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method("#{name}") { instance_variable_get("@#{name}") }
      define_method("#{name}=") do |arg|
        instance_variable_set("@#{name}", arg)
      end
    end
  end
end
