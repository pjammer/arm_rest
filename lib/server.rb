require 'net/http'
require 'uri'
require 'json/ext'

module ArmRest
  class Server
    #Here are the customizable variables, app_name, user_name and password.  should be the only thing to change.
    def app_name
      "pjammer"
    end
    def user_name
      "admin"
    end
    def password
      "mysecretpassword"
    end
    #if you have changed anything in the database at all, adjust this url to look like what you have.
    # eg., maybe you don't use authentication yet change it to "http://127.0.0.1:5984/#{app_name}_#{environment}"
    def database(environment)
      "https://pjammer.cloudant.com/testbin"
    end
    #First create your 3 databases with your AppName_environment, e.g., basecamp_development, basecamp_test and basecamp_production.  This thing automagically expects this naming convention... for now.
    def initialize(options = nil)
      url = URI.parse("https://pjammer.cloudant.com/testbin")
      @host = url.host
      @port = url.port
      @path = url.path
      @options = options
    end
    # Delete the fucking thing, um, leave the arg blank to cancel the DB if i ain't mistaken.
    def delete(uri = nil)
      requestor(Net::HTTP::Delete.new(build_uri(uri)))
    end
    #Your workhorse for looking up shit, use server (an instantiated ArmRest::Server) like, server.get("the_name_of_your_id")
    def get(uri)
      req = requestor(Net::HTTP::Get.new(build_uri(uri)))
      parse req.body
    end
    #PUT is used to update documents. E.g.,  server.put('id', {:valid => "json here"}) should work.
    def put(json, uri = nil)
      req = Net::HTTP::Put.new(build_uri(uri))
      prepare_doc(req, json)
    end
    #POST to @path to get the doc created.  It works how you'd think it should.
    def post(json, uri = nil)
      req = Net::HTTP::Post.new(build_uri(uri))
      prepare_doc(req, json)
    end
    def create_design_doc(name, function_hash)
      @name = build_name(name)
      @functions = viewize function_hash
      put(@functions, @name)
    end
    def viewize(functions)
      {:views => functions}
    end
    def build_name(name)
      "_design/#{name}"
    end
    
    private
    #Used to automate the actual database name from your calls to the db, letting you just worry about the document id.
    def build_uri(uri = nil)
      if uri.nil?
        "#{@path}"
      else
        ["#{@path}", uri].join("/")
      end
    end
    #Once you create your url and send it out to couch, the response will come back into this request variable to make sure it's a response it expects, or else it handles the error
    def requestor(req, json = nil)
      res = Net::HTTP.start(@host, @port, {:use_ssl => true}) { |http| 
        requesty = req
        requesty.basic_auth("pjammer", "rockpapertroubletime")
        requesty["content-type"] = "application/json"
        requesty.body = JSON json unless json.nil?
        http.request(requesty)
      }
      unless res.kind_of?(Net::HTTPSuccess)
        # let rails and sinatra handle this or print out if using ruby i say if, elsif, else
        handle_error(req, res)
      end
      res
    end
    #Refactored area of Post and Put that puts content type and json into .body
    def prepare_doc(req, json)
      var = requestor(req, json)
      parse var.body
    end
    # used in Get request above, so that you can just use @var["id"] right away in controllers/views.
    def parse(arg)
      JSON.parse(arg)
    end

    def handle_error(req, res)
      e = RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
      raise e
    end
  end
end
