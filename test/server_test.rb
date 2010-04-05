require 'rubygems'
require "test/unit"
require "lib/server"
require "json"

class ServerTest < Test::Unit::TestCase
  #puts are tested in setup, so chillax.. if it don't work, nothing works.
  def setup
    @server = ArmRest::Server.new("test")
    @doc = "randa_#{rand(1000)}"
    @data = @server.put(@doc, {:name => "here we are", :user => "works", :created_at => Time.now})
  end
  
  # def teardown
  #   @server.delete
  # end
     
  def test_get
    actual = @server.get(@doc)
    assert_equal "here we are", actual["name"]
  end
  
  
  def test_delete_doc
    del_data_doc = "delete#{rand(1000)}"
    del_doc = @server.put(del_data_doc, {:name => "here we are", :user => "works", :created_at => Time.now})
    the_bye = [del_doc["id"], del_doc["rev"]].join("?rev=")
    deleted_doc = @server.delete(the_bye.to_s)
    assert_raise RuntimeError do 
      @server.get(del_doc["id"])
    end
  end
end