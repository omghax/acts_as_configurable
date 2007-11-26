require "test/unit"
require "rubygems"
require "activerecord"

$:.unshift File.dirname(__FILE__) + "/../lib"
require File.dirname(__FILE__) + "/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table(:blogs) { |t| t.column :settings, :text }
end

class Blog < ActiveRecord::Base
  acts_as_configurable

  setting :string, :type => :string
  setting :string_with_default, :type => :string, :default => "default"

  setting :integer, :type => :integer
  setting :integer_with_default, :type => :integer, :default => 0

  setting :boolean, :type => :boolean
  setting :boolean_with_default, :type => :boolean, :default => true
end

class TestActsAsConfigurable < Test::Unit::TestCase
  def test_defaults
    assert_nil              Blog.new.string
    assert_equal "default", Blog.new.string_with_default
    assert_nil              Blog.new.integer
    assert_equal 0,         Blog.new.integer_with_default
    assert_nil              Blog.new.boolean
    assert_equal true,      Blog.new.boolean_with_default
  end

  def test_string_setter
    assert_equal "custom",  Blog.new(:string => "custom").string
    assert_equal "123",     Blog.new(:string => 123).string
    assert_equal "false",   Blog.new(:string => false).string
    assert_equal "",        Blog.new(:string => nil).string
  end

  def test_integer_setter
    assert_equal 123, Blog.new(:integer => 123).integer
    assert_equal 123, Blog.new(:integer => "123").integer
    assert_equal 0,   Blog.new(:integer => "custom").integer
    assert_equal 0,   Blog.new(:integer => false).integer
    assert_equal 0,   Blog.new(:integer => nil).integer
  end

  def test_boolean_setter
    assert Blog.new(:boolean => true).boolean?
    assert Blog.new(:boolean => "true").boolean?
    assert Blog.new(:boolean => "t").boolean?
    assert Blog.new(:boolean => 1).boolean?
    assert Blog.new(:boolean => "1").boolean?

    assert !Blog.new(:boolean => false).boolean?
    assert !Blog.new(:boolean => "false").boolean?
    assert !Blog.new(:boolean => "f").boolean?
    assert !Blog.new(:boolean => 0).boolean?
    assert !Blog.new(:boolean => "0").boolean?
    assert !Blog.new(:boolean => nil).boolean?
  end
end
