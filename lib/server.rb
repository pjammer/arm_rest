require 'net/http'
require 'uri'
require 'json'
# require 'rest_client'

module ArmRest
  class Server
    #Here are the customizable variables, app_name, user_name and password.  should be the only thing to change.
    def app_name
      "wigplan"
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
      "http://#{user_name}:#{password}@127.0.0.1:5984/#{app_name}_#{environment}"
    end
    #First create your 3 databases with your AppName_environment, e.g., basecamp_development, basecamp_test and basecamp_production.  This thing automagically expects this naming convention... for now.
    def initialize(env, options = nil)
      url = URI.parse(database(env))
      @host = url.host
      @port = url.port
      @path = url.path
      @options = options
    end
    #Used to automate the actual database name from your calls to the db, letting you just worry about the document id.
    def build_uri(uri)
      ["#{@path}", uri].join("/")
    end
    # Delete the fucking thing, um, leave the arg blank to cancel the DB if i ain't mistaken.
    def delete(uri = nil)
      request(Net::HTTP::Delete.new(build_uri(uri)))
    end
    #Your workhorse for looking up shit, use server (an instantiated ArmRest::Server) like, server.get("the_name_of_your_id")
    def get(uri)
      req = request(Net::HTTP::Get.new(build_uri(uri)))
      parse req.body
    end
    #supposedly server.put('id', some_input_variable) should work.
    #pass put a hash for now, and we'll convert to json.
    def put(uri, json)
      req = Net::HTTP::Put.new(build_uri(uri))
      prepare_doc(req, json)
    end
    #not sure, but somehow POST is the black sheep. gonna figure out why.
    def post(uri, json)
      req = Net::HTTP::Post.new(build_uri(uri))
      prepare_doc(req, json)
    end
    
    private
    #Once you create your url and send it out to couch, the response will come back into this request variable to make sure it's a response it expects, or else it handles the error
    def request(req)
      res = Net::HTTP.start(@host, @port) { |http|http.request(req) }
      unless res.kind_of?(Net::HTTPSuccess)
        # let rails and sinatra handle this or print out if using ruby i say if, elsif, else
        handle_error(req, res)
      end
      res
    end
    #Refactored area of Post and Put that puts content type and json into .body
    def prepare_doc(req, json)
      req["content-type"] = "application/json"
      req.body = json.to_json
      var = request(req)
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