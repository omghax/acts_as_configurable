require "test/unit"
require "rubygems"
require "activerecord"

$:.unshift File.dirname(__FILE__) + "/../lib"
require File.dirname(__FILE__) + "/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :blogs do |t|
    t.column :settings, :text
  end
end

class Blog < ActiveRecord::Base
  acts_as_configurable

  setting :string_with_no_default, :type => :string
  setting :string_with_default, :type => :string, :default => "default"

  setting :integer_with_no_default, :type => :integer
  setting :integer_with_default, :type => :integer, :default => 0

  setting :boolean_with_no_default, :type => :boolean
  setting :boolean_with_default, :type => :boolean, :default => true
end

class TestActsAsConfigurable < Test::Unit::TestCase
  def test_defaults
    blog = Blog.new
    assert_nil blog.string_with_no_default
    assert_equal "default", blog.string_with_default
    assert_nil blog.integer_with_no_default
    assert_equal 0, blog.integer_with_default
    assert_nil blog.boolean_with_no_default
    assert_equal true, blog.boolean_with_default
  end

  def test_string_setter
    {
      "custom" => "custom",
      123      => "123",
      false    => "false",
      nil      => ""
    }.each do |given, expected|
      blog = Blog.new
      blog.string_with_no_default = given
      actual = blog.string_with_no_default
      assert_equal expected, actual, "expected string value #{expected.inspect} for given value #{given.inspect}, got #{actual.inspect}"
    end
  end

  def test_string_query_methods
    blog = Blog.new
    assert !blog.string_with_no_default?
    blog.string_with_no_default = "custom"
    assert blog.string_with_no_default?
    blog.string_with_no_default = ""
    assert !blog.string_with_no_default?
  end

  def test_integer_setter
    {
      "custom" => 0,
      123      => 123,
      "123"    => 123,
      false    => 0,
      nil      => 0
    }.each do |given, expected|
      blog = Blog.new
      blog.integer_with_no_default = given
      actual = blog.integer_with_no_default
      assert_equal expected, actual, "expected integer value #{expected.inspect} for given value #{given.inspect}, got #{actual.inspect}"
    end
  end

  def test_integer_query_methods
    blog = Blog.new
    assert !blog.integer_with_no_default?
    blog.integer_with_no_default = 1
    assert blog.integer_with_no_default?
    blog.integer_with_no_default = 0
    assert blog.integer_with_no_default?
  end

  def test_boolean_setter
    {
      "true"  => true,
      "t"     => true,
      1       => true,
      "1"     => true,
      true    => true,
      "false" => false,
      "f"     => false,
      0       => false,
      "0"     => false,
      false   => false,
      nil     => false
    }.each do |given, expected|
      blog = Blog.new
      blog.boolean_with_no_default = given
      actual = blog.boolean_with_no_default
      assert_equal expected, actual, "expected boolean value #{expected.inspect} for given value #{given.inspect}, got #{actual.inspect}"
    end
  end

  def test_boolean_query_methods
    blog = Blog.new
    assert !blog.boolean_with_no_default?
    blog.boolean_with_no_default = true
    assert blog.boolean_with_no_default?
    blog.boolean_with_no_default = false
    assert !blog.boolean_with_no_default?
    blog.boolean_with_no_default = nil
    assert !blog.boolean_with_no_default?
  end
end
