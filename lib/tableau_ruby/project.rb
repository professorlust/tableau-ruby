module Tableau
  class Project

    def initialize(client)
      @client = client
    end

    def all(site_name, params={})
      resp = @client.conn.get "/api/2.0/sites" do |req|
        params.each {|k,v| req.params[k] = v}
        req.params['includeProjects'] = 'true'
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      data = {sites: []}
      doc = Nokogiri::XML(resp.body)
      doc.css("tsResponse sites site").each do |s|
        next unless s['name'].downcase == site_name.downcase
        @projects = {projects: []}
        s.css("project").each do |p|
          @projects[:projects] << {id: p["id"], name: p["name"]}
        end
      end
      @projects.to_json
    end

  end
end