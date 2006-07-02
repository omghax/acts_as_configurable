module ActsAsConfigurable
  def acts_as_configurable(attr_name = :settings, type = Hash)
  	extend ClassMethods
    serialize(attr_name, type)
    define_method(:settings_column) { send(attr_name) }
    define_method(:settings_column=) { |new_value| send("#{attr_name}=", new_value) }
  end

  private
  
  module ClassMethods
    protected
    
    def setting(key, ruby_type = :object, default = nil)
    	item = Item.new
    	item.key, item.ruby_type, item.default = key.to_s, ruby_type, default
    	add_setting_reader(item)
    	add_setting_writer(item)
    end

    private
    
    def add_setting_reader(item)
    	define_method(item.key) do
    		raw = self.settings_column[item.key] rescue nil
    		raw.nil? ? item.default : raw
    	end
      alias_method("#{item.key}?", item.key) if [:boolean, :bool].include?(item.ruby_type)
    end

    def add_setting_writer(item)
    	define_method("#{item.key}=") do |new_value|
        self.settings_column ||= {}
    	  retval = self.settings_column[item.key] = item.canonicalize(new_value)
        save unless new_record?
        retval
      end
    end

    class Item
    	attr_accessor :key, :ruby_type, :default
    	
    	def canonicalize(value)
    		case ruby_type
  			when :boolean, :bool
          ![0, '0', '', false, 'false', 'f', nil].include?(value)
        when :integer, :int
        	value.is_a?(String) ? value.gsub(/[^0-9\.]/, '').to_i : value.to_i
        when :float
          value.is_a?(String) ? value.gsub(/[^0-9\.]/, '').to_f : value.to_f
        when :string, :str
        	value.to_s
        when :yaml, :yml
        	value.to_yaml
        else
          value
    		end
    	end
    end
  end
end
