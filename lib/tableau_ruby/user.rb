module Tableau
  class User

    attr_accessor :id, :name, :role, :publish, :content_admin, :last_login, :external_auth_user_id, :site_id, :workbooks, :projects

    def initialize(client, u)
      @client                = client
      @id                    = u['id']
      @name                  = u['name']
      @role                  = u['role']
      @publish               = u['publish']
      @content_admin         = u['contentAdmin']
      @last_login            = u['lastLogin']
      @external_auth_user_id = u['externalAuthUserId']
      @site_id               = @client.site_id
    end

    def workbooks(options={})
      resp = @client.conn.get "/api/2.0/sites/#{@site_id}/users/#{@id}/workbooks" do |req|
        req.params['pageSize'] = options[:page_size] if options[:page_size]
        req.params['pageNumber'] = options[:page_number] if options[:page_number]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {workbooks: [], pagination: {}}

      Nokogiri::XML(resp.body).css("pagination").each do |p|
        data[:pagination][:page_number] = p['pageNumber']
        data[:pagination][:page_size] = p['pageSize']
        data[:pagination][:total_available] = p['totalAvailable']
      end

      Nokogiri::XML(resp.body).css("workbook").each do |w|
        wkbk = {id: w["id"], name: w["name"], project: {}, views: [], tags: []}

        w.css('project').each do |p|
          wkbk[:project] = {id: p['id'], name: p['name']}
        end

        w.css("view").each do |v|
          wkbk[:views] << v['id']
        end

        w.css("tag").each do |t|
          wkbk[:tags] << t['id']
        end

        data[:workbooks] << wkbk
      end

      data.to_json
    end

  end
end