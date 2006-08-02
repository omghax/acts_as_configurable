require 'test/unit'
require "#{File.dirname(__FILE__)}/mocks/model"

class ActsAsConfigurableTest < Test::Unit::TestCase
  def setup
  	@model = Test::ActiveRecord::Model.new
  end

  def test_setting_readers
    assert_equal 'string1', @model.string1
    assert_equal 'string2', @model.string2
    assert_equal 1, @model.integer1
    assert_equal 2, @model.integer2
    assert_equal 1.00, @model.float1
    assert @model.boolean1
    assert @model.boolean1?
    assert @model.boolean2
    assert @model.boolean2?
  end

  def test_setting_writers
    {'new string1' => 'new string1', 'new string2' => 'new string2'}.each do |value, expected|
      @model.string1 = value
      assert_equal expected, @model.string1
    	@model.string2 = value
    	assert_equal expected, @model.string2
    end

    {10 => 10, 20 => 20}.each do |value, expected|
      @model.integer1 = value
      assert_equal expected, @model.integer1
      @model.integer2 = value
      assert_equal expected, @model.integer2
    end

    {10.00 => 10.00, 20.00 => 20.00}.each do |value, expected|
      @model.float1 = value
      assert_equal expected, @model.float1
    end

    {false => false, true => true}.each do |value, expected|
    	@model.boolean1 = value
    	assert_equal expected, @model.boolean1
    	assert_equal expected, @model.boolean1?
    	@model.boolean2 = value
    	assert_equal expected, @model.boolean2
    	assert_equal expected, @model.boolean2?
    end
  end

  def test_canonicalize
    {Class => 'Class', 1 => '1', true => 'true'}.each do |value, expected|
      @model.string1 = value
      assert_equal expected, @model.string1
    end

    {'10' => 10, '1,000' => 1000, '$100' => 100, '1.05' => 1}.each do |value, expected|
      @model.integer1 = value
      assert_equal expected, @model.integer1
    end

    {'10.00' => 10.00, '1,000' => 1000.00, '$100.00' => 100.00, '1.05' => 1.05}.each do |value, expected|
      @model.float1 = value
      assert_equal expected, @model.float1
    end

    {'false' => false, 'f' => false, 0 => false, '0' => false, '' => false, nil => false}.each do |value, expected|
      @model.boolean1 = value
      assert_equal expected, @model.boolean1
    end
  end
end
