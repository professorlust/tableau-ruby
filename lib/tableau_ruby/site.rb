module Tableau
  class Site
    API_URL = "http://fxawstableau02/api/2.0/"

  	def all(token, include_projects=false)
  		resp = http_request("sites/", nil, "get", token)
  		puts resp.inspect
  	end

  	def http_request(path, payload, method, token=nil)
      Faraday.send(method) do |request|
        request.url  API_URL+path
        request.headers['Content-Type'] = 'application/xml'
        request.headers['X-Tableau-Auth'] = token
        request.body = payload
      end
    end

  end
end