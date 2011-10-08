require 'net/http'
require 'uri'
require 'json/ext'
module ArmRest
  #ArmRest is the missing Ruby to CouchDB gem.  There are others but fucked if i could figure them out.
  #Basically, ArmRest will work with Cloudant, Heroku and Sinatra.
  #We are going to look for the wiki to really show you the flow.  Or the tests.
  class Server
    #Basically set up sinatra to use a ENV["CLOUDANT_URL"] = "https://user:password@yourname.cloudant.com/somedbname".
    def initialize(db_uri, options = nil)
      url = URI.parse(db_uri)
      @host = url.host
      @port = url.port
      @path = url.path
      @user = url.user
      @passwd = url.password
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
    #use find for design documents
    def find(doc_name, view, params=nil)
      design_doc_url = build_design_uri(doc_name, view, params)
      get(design_doc_url)
    end
    #add a key to a view
    def add_key(arg)
      "key=#{arg.to_json}"
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
    #sample design doc function func = {:wicked => {"map" => "function(doc) { emit(doc._id, doc); }"}}
    def create_design_doc(name, function_hash)
      @name = build_name(name)
      @functions = viewize function_hash
      put(@functions, @name)
    end
    #add validations and where style keys find(name, view).key
    private
    #creates the view json call
    def viewize(functions)
      {:views => functions}
    end
    #adds name to design document in format couchdb needs
    def build_name(name)
      "_design/#{name}"
    end
    
    def build_design_uri(doc_name, view_name, params)
      url = "#{build_name(doc_name)}/_view/#{view_name}"
      params.nil? ? url : "#{url}?#{params}"
    end
    
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
        create_the_request(req, json, http)
      }
      unless res.kind_of?(Net::HTTPSuccess)
        # let rails and sinatra handle this or print out if using ruby i say if, elsif, else
        handle_error(req, res)
      end
      res
    end
    def create_the_request(req, json, http) 
      req.basic_auth(@user, @passwd)
      req["content-type"] = "application/json"
      req.body = JSON json unless json.nil?
      http.request(req)
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
      raise RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
    end
  end
end
