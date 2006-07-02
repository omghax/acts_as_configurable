require 'test/unit'
require "#{File.dirname(__FILE__)}/mock_model"

class ActsAsConfigurableTest < Test::Unit::TestCase
  def setup
  	@model = MockModel.new
  end

  def test_setting_readers
    assert_equal @model.string1, 'string1'
    assert_equal @model.string2, 'string2'
    assert_equal @model.integer1, 1
    assert_equal @model.integer2, 2
    assert_equal @model.float1, 1.00
    assert @model.boolean1
    assert @model.boolean1?
    assert @model.boolean2
    assert @model.boolean2?
  end

  def test_setting_writers
    {'new string1' => 'new string1', 'new string2' => 'new string2'}.each do |value, expected|
      @model.string1 = value
      assert_equal @model.string1, expected
    	@model.string2 = value
    	assert_equal @model.string2, expected
    end

    {10 => 10, 20 => 20}.each do |value, expected|
      @model.integer1 = value
      assert_equal @model.integer1, expected
      @model.integer2 = value
      assert_equal @model.integer2, expected
    end

    {10.00 => 10.00, 20.00 => 20.00}.each do |value, expected|
      @model.float1 = value
      assert_equal @model.float1, expected
    end

    {false => false, true => true}.each do |value, expected|
    	@model.boolean1 = value
    	assert_equal @model.boolean1, expected
    	assert_equal @model.boolean1?, expected
    	@model.boolean2 = value
    	assert_equal @model.boolean2, expected
    	assert_equal @model.boolean2?, expected
    end
  end

  def test_canonicalize
    {Class => 'Class', 1 => '1', true => 'true'}.each do |value, expected|
      @model.string1 = value
      assert_equal @model.string1, expected
    end

    {'10' => 10, '1,000' => 1000, '$100' => 100, '1.05' => 1}.each do |value, expected|
      @model.integer1 = value
      assert_equal @model.integer1, expected
    end

    {'10.00' => 10.00, '1,000' => 1000.00, '$100.00' => 100.00, '1.05' => 1.05}.each do |value, expected|
      @model.float1 = value
      assert_equal @model.float1, expected
    end

    {'false' => false, 'f' => false, 0 => false, '0' => false, '' => false, nil => false}.each do |value, expected|
      @model.boolean1 = value
      assert_equal @model.boolean1, expected
    end
  end
end
