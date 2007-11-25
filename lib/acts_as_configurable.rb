module ActsAsConfigurable
  private
  
  module SingletonMethods
    # Define a setting.
    # 
    # Example:
    #   setting :title, :type => :string, :default => 'default title'
    # 
    # Options:
    # [type]    The type of data that will be stored by this setting.
    #           Defaults to :object.
    # [default] Specifies the default value for this setting.  This value
    #           will be returned if no other value has been set yet.
    #           Defaults to nil.
    # 
    # The available types are:
    # 
    # [:boolean]  boolean values
    # [:integer]  integer values
    # [:float]    floating-point values
    # [:string]   string values
    # [:yaml]     YAML values
    # [:object]   any object (ActiveRecord must be able to serialize it)
    def setting(key, options = {})
      add_setting_accessor(Item.new(key, options))
    end

    private
    
    def add_setting_accessor(item) # :nodoc:
    	add_setting_reader(item)
    	add_setting_writer(item)
    end
    
    def add_setting_reader(item) # :nodoc:
    	define_method(item.key) do
    		raw = send(acts_as_configurable_options[:using])[item.key] rescue nil
    		raw.nil? ? item.default : raw
    	end
      define_method("#{item.key}?") do
        raw = send(acts_as_configurable_options[:using])[item.key] rescue nil
        !raw.blank?
      end
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
    	attr_reader :key, :default
    	
    	def initialize(key, options = {})
        options.symbolize_keys!.reverse_merge!(:type => :object, :default => nil)
      	@key, @ruby_type, @default = key.to_s, options[:type].to_sym, options[:default]
    	end
    	
    	def canonicalize(value)
    		case @ruby_type
  			when :boolean, :bool
  			  ![0, '0', '', false, 'false', 'f', nil].include?(value)
				when :integer, :int
          if value.respond_to?(:to_i)
            value.to_i
          else
            value ? 1 : 0
          end
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
  
  module ClassMethods
    # This act provides user-defined settings with default
    # values, using a text column to store a serialized
    # Hash of setting keys and values.
    # 
    # Example:
    #   acts_as_configurable :using => :settings
    # 
    # Options:
    # [using]     The name of the text column where your settings will be
    #             stored.  Defaults to :settings.
    # [autosave]  Specifies whether or not you would like to save the
    #             record every time a setting is changed.  This is only
    #             active in existing records, so you won't risk saving
    #             a new record before you're ready.  Defaults to false.
    def acts_as_configurable(options = {})
      options.symbolize_keys!.reverse_merge!(:using => :settings, :type => Hash, :autosave => true)
    	write_inheritable_hash(:acts_as_configurable_options, options)
    	class_inheritable_reader :acts_as_configurable_options
      serialize(options[:using], Hash)
    	extend SingletonMethods
    end
  end
end

module ActsAsConfigurable
  def self.included(base) # :nodoc:
    super
    base.extend(ClassMethods)
  end
end
