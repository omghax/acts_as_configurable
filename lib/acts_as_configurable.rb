# = ActsAsConfigurable
# 
# This is the ActsAsConfigurable plugin.  It allows you to add
# user-defined setting values to your models, as well as default
# fallback values.  Usage is simple, just type
# 
#   acts_as_configurable [:using => :settings], [:type => Hash], [:autosave => true]
#
# where :using is the name of the text column to store your
# settings in (default is :settings), :type is the type of
# data to store the settings as (default is Hash, but you could
# also use a HashWithIndifferentAccess), and :autosave is
# whether or not you'd like a save each record when its settings
# are changed (default is true).
# 
# == Adding Settings
#
# Now that you've defined your model as configurable, you can
# add fields using the setting method like so:
# 
#   setting :key, :type => :object_type, :default => :default_value
#   
# where :key is the name of the setting, :object_type is the
# type, and :default_value is the default value.  The
# type can be any one of the following:
# 
#   :bool,  :boolean = boolean values
#   :int,   :integer = integer values
#   :float           = floating-point values
#   :str,   :string  = string values
#   :yml,   :yaml    = YAML values
#   :object          = any object (ActiveRecord must be able to serialize it)
#
# So, let's say we wanted a 'title' setting for our Site model.
# Here's how it would look:
#
#   class Site < ActiveRecord::Base
#     acts_as_configurable
#     setting :title, :type => :string, :default => 'Default title'
#   end
#
# == Reading Settings
#
# Using our site example above, we can now access any site's
# title using:
# 
#   # This will return 'Default title'.
#   @site.title
#
# where @site is an instance of our Site model.  We can also
# set values in the same way:
#
#   # This will set @site.title to 'New title'.
#   @site.title = 'New title'
#
#   # This will now return 'New title'.
#   @site.title
#
# == Boolean Settings
#
# Settings defined as type :boolean or :bool can also be accessed
# with a query method, like this:
# 
#   # These will both return true.
#   @instance.boolean_setting
#   @instance.boolean_setting?
#   
# == Saving
#
# By default, acts_as_configurable will save a record whenever
# a setting has changed, unless that record is new and does not
# yet exist in the database.  You can disable this behavior when
# defining acts_as_configurable by setting the :autosave option
# to false.
#
# Example:
#
#   # We don't want acts_as_configurable to save any records.
#   acts_as_configurable :autosave => false
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
  private
  
  # Singleton methods for ActsAsConfigurable.
  #
  module SingletonMethods
    # Define a setting.
    #
    # Example:
    #   setting :title, :type => :string, :default => 'default title'
    #
    # Configuration options are:
    #   * type - the type of object to use for
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
    def setting(key, options = {})
    	item = Item.new(key, options)
    	add_setting_reader(item)
    	add_setting_writer(item)
    end

    private
    
    def add_setting_reader(item) # :nodoc:
    	define_method(item.key) do
    		raw = send(acts_as_configurable_options[:using])[item.key] rescue nil
    		raw.nil? ? item.default : raw
    	end
      alias_method("#{item.key}?", item.key) if [:boolean, :bool].include?(item.ruby_type)
    end

    def add_setting_writer(item) # :nodoc:
    	define_method("#{item.key}=") do |new_value|
    	  column = send(acts_as_configurable_options[:using])
    	  column ||= send("#{acts_as_configurable_options[:using]}=", acts_as_configurable_options[:type].new)
        new_value = item.canonicalize(new_value)
        unless column[item.key] == new_value
      	  column[item.key] = new_value
      	  save if acts_as_configurable_options[:autosave] and not new_record?
        end
    	  new_value
    	end
    end
    
    class Item # :nodoc:
    	attr_reader :key, :ruby_type, :default
    	
    	def initialize(key, options = {})
      	options = {:type => :object, :default => nil}.update(options.symbolize_keys)
      	@key, @ruby_type, @default = key.to_sym, options[:type].to_sym, options[:default]
    	end
    	
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

module ActsAsConfigurable
  private
  
  # Class methods for ActsAsConfigurable. They are broken out this way so that they
  # can be fed to base.extend(), using Ruby interpreter magic so that class methods
  # of this module work while a class including it is still being defined.
  #
  module ClassMethods
    # This act provides user-defined settings with default
    # values, using a text column to store a serialized
    # Hash of setting keys and values.
    #
    # Example:
    #   acts_as_configurable :using => :settings, :type => Hash
    #
    # Configuration options are:
    #   * using - the name of the column to store the
    #     serialized settings in (default: settings).
    #   * type - the class to serialize when saving the
    #     settings to the database (default: Hash).
    #   * autosave - whether or not to autosave the record
    #     when a setting is changed (default: true).
    #
    def acts_as_configurable(options = {})
    	options = {:using => :settings, :type => Hash, :autosave => true}.update(options.symbolize_keys)
    	write_inheritable_hash(:acts_as_configurable_options, options)
    	class_inheritable_reader :acts_as_configurable_options
      serialize(options[:using], options[:type])
    	extend SingletonMethods
    end
  end
end

module ActsAsConfigurable
  def self.append_features(base)
    super
    base.extend(ClassMethods)
  end
end
