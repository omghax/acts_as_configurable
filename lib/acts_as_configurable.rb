# = ActsAsConfigurable
# 
# This is the ActsAsConfigurable plugin.  It allows you to add
# user-defined setting values to your models, as well as default
# fallback values.  Usage is simple, just type
# 
#   acts_as_configurable [:column], [Type]
#   
# where :column is the name of the text column to store your
# settings in (default is :settings), and Type is the type of
# data to store the settings as (default is Hash, but you
# could also use HashWithIndifferentAccess).
# 
# == Adding Settings
#
# Now that you've defined your model as configurable, you can
# add fields using the setting method like so:
# 
#   setting :string_setting, :string, 'This is the default value'
#   setting :boolean_setting, :boolean, true
#   
# where :string_value is the name of the setting, :string 
# is the type, and the last value is the default value.  The
# type can be any one of the following:
# 
#   :bool,  :boolean = boolean values
#   :int,   :integer = integer values
#   :float           = floating-point values
#   :str,   :string  = string values
#   :yml,   :yaml    = YAML values
#   :object          = any object (ActiveRecord must be able to serialize it)
#   
# == Reading Settings
#
# Going back to our example setting earlier, you may access
# the example setting's value using:
# 
#   # This will return 'This is the default value'.
#   @instance.string_setting
#   
# In addition, boolean settings will also be given a question
# mark method like this:
# 
#   # These will both return true.
#   @instance.boolean_setting
#   @instance.boolean_setting?
#   
# == Writing Settings
#
# To change the setting to a new value, use:
# 
#   # This will set the string setting's
#   # value to 'New value'.
#   @instance.string_setting = 'New value'
# 
#   # This will set the boolean setting's
#   # value to false.
#   @instance.boolean_setting = false
#   
# == Notes
#
# We've been using strings up to this point, but there's no
# reason why you couldn't do the same thing with integers,
# floats, booleans, arrays, hashes, or any other object
# that ActiveRecord can serialize.
# 
# Note that when you change a setting's value, the record is
# automatically saved unless it's a new record that doesn't
# yet exist in the database.
#
module ActsAsConfigurable
  # This act provides user-defined settings with default
  # values, using a text column to store a serialized
  # Hash of setting keys and values.
  #
  # Configuration options are:
  #   * attr_name - the name of the column to store the
  #     serialized settings in (default: settings).
  #   * type - the class to serialize when saving the
  #     settings to the database (default: Hash).
  #
  def acts_as_configurable(attr_name = :settings, type = Hash)
  	extend ClassMethods
    serialize(attr_name, type)
    define_method(:settings_column) { send(attr_name) }
    define_method(:settings_column=) { |new_value| send("#{attr_name}=", new_value) }
  end

  private
  
  module ClassMethods
    protected
    
    # Define a setting.
    #
    # Configuration options are:
    #   * key - the name to use for the setting.
    #   * ruby_type - the type of object to use for
    #     the setting.
    #   * default - the default value to use for
    #     the setting.
    #
    # The available types are:
    #
    #   :bool,  :boolean = boolean values
    #   :int,   :integer = integer values
    #   :float           = floating-point values
    #   :str,   :string  = string values
    #   :yml,   :yaml    = YAML values
    #   :object          = any object (ActiveRecord must be able to serialize it)
    #
    def setting(key, ruby_type = :object, default = nil)
    	item = Item.new
    	item.key, item.ruby_type, item.default = key.to_s, ruby_type, default
    	add_setting_reader(item)
    	add_setting_writer(item)
    end

    private
    
    def add_setting_reader(item) # :nodoc:
    	define_method(item.key) do
        raw = self.settings_column[item.key] rescue nil
        raw.nil? ? item.default : raw
    	end
      alias_method("#{item.key}?", item.key) if [:boolean, :bool].include?(item.ruby_type)
    end

    def add_setting_writer(item) # :nodoc:
    	define_method("#{item.key}=") do |new_value|
        self.settings_column ||= {}
    	  retval = self.settings_column[item.key] = item.canonicalize(new_value)
        save unless new_record?
        retval
      end
    end

    class Item # :nodoc:
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
