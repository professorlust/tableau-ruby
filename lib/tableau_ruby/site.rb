module Tableau
  class Site

  	def initialize(client)
  		@client = client
  	end

  	def all(params={})
  		resp = @client.conn.get "/api/2.0/sites" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
  		end
  		data = {sites: []}
  		Nokogiri::XML(resp.body).css("tsResponse sites site").each do |s|
  			data[:sites] << {name: "#{s['name']}", id: "#{s['id']}", content_url: "#{s['contentUrl']}", admin_mode: "#{s['adminMode']}", user_quota: "#{s['userQuota']}", storage_quota: "#{s['storageQuota']}", state: "#{s['state']}", status_reason: "#{s['statusReason']}"}
			end
			data.to_json
  	end

  	def find(site_id, params={})
  		resp = @client.conn.get "/api/2.0/sites/#{site_id}" do |req|
  			params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
  		end

	  	puts resp.body
  	end

  end
end