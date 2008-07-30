require "test/unit"
require "rubygems"
require "activerecord"
require "active_record/version"

$:.unshift File.dirname(__FILE__) + "/../lib"
require File.dirname(__FILE__) + "/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table(:people_using_preferences) { |t| t.column :preferences, :text }
  create_table(:people_using_settings) { |t| t.column :settings, :text }
end

class PersonUsingPreferences < ActiveRecord::Base
  set_table_name "people_using_preferences"
  acts_as_configurable :using => :preferences do |c|
    c.string :string
    c.integer :integer
    c.boolean :boolean
  end
end

class PersonUsingSettings < ActiveRecord::Base
  set_table_name "people_using_settings"
  acts_as_configurable do |c|
    c.string :string
    c.string :string_with_default, :default => "default"

    c.integer :integer
    c.integer :integer_with_default, :default => 0

    c.boolean :boolean
    c.boolean :boolean_with_default, :default => true
  end
end

class TestActsAsConfigurable < Test::Unit::TestCase
  def self.when_ar_version(required_version, test_name)
    if ActiveRecord::VERSION::STRING >= required_version
      yield
    else
      $stderr.puts "Skipping #{test_name}: ActiveRecord #{required_version} required."
    end
  end

  def test_serialized_attributes
    assert_equal({"string" => "string", "integer" => 1, "boolean" => true}, PersonUsingPreferences.new(:string => "string", :integer => 1, :boolean => true).preferences)
    assert_equal({"string" => "string", "integer" => 1, "boolean" => true}, PersonUsingSettings.new(:string => "string", :integer => 1, :boolean => true).settings)
  end

  def test_defaults
    assert_nil              PersonUsingSettings.new.string
    assert_equal "default", PersonUsingSettings.new.string_with_default
    assert_nil              PersonUsingSettings.new.integer
    assert_equal 0,         PersonUsingSettings.new.integer_with_default
    assert_nil              PersonUsingSettings.new.boolean
    assert_equal true,      PersonUsingSettings.new.boolean_with_default
  end

  def test_string_setter
    assert_equal "custom",  PersonUsingSettings.new(:string => "custom").string
    assert_equal "123",     PersonUsingSettings.new(:string => 123).string
    assert_equal "false",   PersonUsingSettings.new(:string => false).string
    assert_equal "",        PersonUsingSettings.new(:string => nil).string
  end

  def test_integer_setter
    assert_equal 123, PersonUsingSettings.new(:integer => 123).integer
    assert_equal 123, PersonUsingSettings.new(:integer => "123").integer
    assert_equal 0,   PersonUsingSettings.new(:integer => "custom").integer
    assert_equal 0,   PersonUsingSettings.new(:integer => false).integer
    assert_equal 0,   PersonUsingSettings.new(:integer => nil).integer
  end

  def test_boolean_setter
    assert PersonUsingSettings.new(:boolean => true).boolean?
    assert PersonUsingSettings.new(:boolean => "true").boolean?
    assert PersonUsingSettings.new(:boolean => "t").boolean?
    assert PersonUsingSettings.new(:boolean => 1).boolean?
    assert PersonUsingSettings.new(:boolean => "1").boolean?

    assert !PersonUsingSettings.new(:boolean => false).boolean?
    assert !PersonUsingSettings.new(:boolean => "false").boolean?
    assert !PersonUsingSettings.new(:boolean => "f").boolean?
    assert !PersonUsingSettings.new(:boolean => 0).boolean?
    assert !PersonUsingSettings.new(:boolean => "0").boolean?
    assert !PersonUsingSettings.new(:boolean => nil).boolean?
  end

  # Dirty attributes only exist in ActiveRecord >= 2.1.0
  when_ar_version("2.1.0", "dirty attributes test") do
    def test_changing_attributes_dirties_settings_column
      person = PersonUsingSettings.create!(:boolean => false)
      assert ! person.settings_changed?
      person.boolean = true
      assert person.settings_changed?
    end
  end
end
