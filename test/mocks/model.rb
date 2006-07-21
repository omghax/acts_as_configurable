require "#{File.dirname(__FILE__)}/../../lib/acts_as_configurable"

module Mocks
  class Model
    attr_accessor :settings, :new_record
    alias :new_record? :new_record

    def initialize;	new_record = true; end
    def self.serialize(attr_name, type = Hash); end
    def save; new_record = false; end

    extend ActsAsConfigurable
    acts_as_configurable :settings

    setting :string1, :string, 'string1'
    setting :string2, :str, 'string2'
    setting :integer1, :integer, 1
    setting :integer2, :int, 2
    setting :float1, :float, 1.00
    setting :boolean1, :boolean, true
    setting :boolean2, :bool, true
  end
end
