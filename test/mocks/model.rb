require "#{File.dirname(__FILE__)}/../../lib/acts_as_configurable"

class Hash
	def symbolize_keys
    inject({}) { |options, (key, value)| options.merge(key.to_sym => value) }
	end
end

module Test
  module ActiveRecord
    class Base
    	include ActsAsConfigurable

      @@inheritable_attributes = {}

      attr_accessor :new_record, :saved
      alias :new_record? :new_record
      alias :saved? :saved

      def initialize
      	@new_record, @saved = true, false
      end

      def save
      	@new_record, @saved = false, true
      end
  
      def self.class_inheritable_reader(name)
      	define_method(name) { self.class.read_inheritable_attribute(name) }
      end
      
      def self.read_inheritable_attribute(name)
      	@@inheritable_attributes[name]
      end

      def self.write_inheritable_attribute(name, value)
      	@@inheritable_attributes[name] = value
      end

      def self.write_inheritable_hash(name, value)
        @@inheritable_attributes[name] ||= {}
      	@@inheritable_attributes[name] = @@inheritable_attributes[name].merge(value)
      end

      def self.serialize(attr_name, type = Hash)
      end
    end

    class Model < Base
      attr_accessor :settings

      acts_as_configurable

      setting :string1, :type => :string, :default => 'string1'
      setting :string2, :type => :str, :default => 'string2'
      setting :integer1, :type => :integer, :default => 1
      setting :integer2, :type => :int, :default => 2
      setting :float1, :type => :float, :default => 1.00
      setting :boolean1, :type => :boolean, :default => true
      setting :boolean2, :type => :bool, :default => true
    end
  end
end
