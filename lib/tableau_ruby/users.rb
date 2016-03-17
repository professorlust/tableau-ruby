module Tableau
  class Users

    attr_reader :workbooks

    def initialize(client)
      @client = client
    end

    def all(params={})
      # return { error: "site_id is missing." }.to_json if params[:site_id].nil? || params[:site_id].empty?
      site_id = params[:site_id] || @client.site_id
      page_size = params[:page_size] || 100
      page_num = params[:page_num] || 1

      resp = @client.conn.get "/api/2.0/sites/#{site_id}/users?pageSize=#{page_size}&pageNumber=#{page_num}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {users: []}
      Nokogiri::XML(resp.body).css("tsResponse users user").each do |u|
        data[:users] << {
          id: u['id'],
          name: u['name'],
          site_id: params[:site_id],
          role: u['role'],
          publish: u['publish'],
          content_admin: u['contentAdmin'],
          last_login: u['lastLogin'],
          external_auth_user_id: u['externalAuthUserId']
        }
      end
      data.to_json
    end

    def find_by(user)
      site_id = user[:site_id] || @client.site_id

      return { error: "site_id is missing." }.to_json if site_id.nil?
      # return { error: "user_id is missing." }.to_json if user.nil? || user.empty?

      resp = query_paged_users(user)
      resp
    end

    def create(user)
      return { error: "name is missing." }.to_json unless user[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.user(
            name: user[:name] || 'New User',
            role: user[:role] || true,
            publish: user[:publish] || true,
            contentAdmin: user[:content_admin] || false,
            suppressGettingStarted: user[:storage_quota] || false
          )
        end
      end

      resp = @client.conn.post "/api/2.0/sites/#{user[:site_id]}/users" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      if resp.status == 201
        normalize_json(resp.body, user[:site_id])
      else
        {error: { status: resp.status, message: resp.body }}.to_json
      end
    end

    def delete(user)
      return { error: "site_id is missing." }.to_json unless user[:site_id]
      return { error: "user id is missing." }.to_json unless user[:id]

      resp = @client.conn.delete "/api/2.0/sites/#{user[:site_id]}/users/#{user[:id]}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      if resp.status == 204
        {success: 'User successfully deleted.'}.to_json
      else
        {errors: resp.status}.to_json
      end
    end

    private

    def query_paged_users(user, page=1)
      resp = @client.conn.get "/api/2.0/sites/#{user[:site_id]}/users?pageSize=1000&pageNumber=#{page}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      pagination = Nokogiri::XML(resp.body).css("tsResponse pagination")
      current_page = pagination.attr("pageNumber").inner_text().to_i
      pages = (pagination.attr('totalAvailable').inner_text().to_f/pagination.attr('pageSize').inner_text().to_f).ceil

      found_user = normalize_json(resp.body, user[:site_id], user[:name])

      if JSON.parse(found_user)['user'].blank? && (current_page + 1 <= pages)
        query_paged_users(user, current_page + 1)
      else
        found_user
      end

    end

    def normalize_json(r, site_id, name=nil)
      data = {user: {}}

      if name
        matched_user = Nokogiri::XML(r).css("user").select { |u| u['name'] == name }.first
      else
        matched_user = Nokogiri::XML(r).css("user")
      end

      unless matched_user.blank?
        data[:user] = {
          id: matched_user['id'],
          name: matched_user['name'],
          site_id: site_id,
          role: matched_user['role'],
          publish: matched_user['publish'],
          content_admin: matched_user['contentAdmin'],
          last_login: matched_user['lastLogin'],
          external_auth_user_id: matched_user['externalAuthUserId']
        }
      end

      data.to_json
    end

  end
end