module Tableau
  class User

    def initialize(client)
      @client = client
    end

    def all(site_id, params={})
      return { error: "site_id is missing." }.to_json if site_id.nil? || site_id.empty?

      resp = @client.conn.get "/api/2.0/sites/#{site_id}/users" do |req|
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {users: []}
      Nokogiri::XML(resp.body).css("tsResponse users user").each do |u|
        data[:users] << {
          id: u['id'],
          name: u['name'],
          role: u['role'],
          publish: u['publish'],
          content_admin: u['contentAdmin'],
          last_login: u['lastLogin'],
          external_auth_user_id: u['externalAuthUserId']
        }
      end
      data.to_json
    end

    def find_by(site_id, user_object, params={})
      return { error: "site_id is missing." }.to_json if site_id.nil? || site_id.empty?
      return { error: "user is missing." }.to_json if user_object.nil? || user_object.empty?

      resp = @client.conn.get "/api/2.0/sites/#{site_id}/users" do |req|
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {}
      Nokogiri::XML(resp.body).css("tsResponse users user").each do |u|
        if u[user_object[0].to_s] == user_object[1]
          data[:user] = {
            id: u['id'],
            name: u['name'],
            role: u['role'],
            publish: u['publish'],
            content_admin: u['contentAdmin'],
            last_login: u['lastLogin'],
            external_auth_user_id: u['externalAuthUserId']
          }
        end
      end

      data.to_json

    end

  end
end