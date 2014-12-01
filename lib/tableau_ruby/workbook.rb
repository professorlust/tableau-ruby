module Tableau
  class Workbook

    def initialize(client)
      @client = client
    end

    def all(site_id, user_id, params={})
      resp = @client.conn.get "/api/2.0/sites/#{site_id}/users/#{user_id}/workbooks" do |req|
        params.each {|k,v| req.params[k] = v}
        req.params['getThumbnails'] = params[:get_thumbnails].nil? ? false : params[:get_thumbnails]
        req.params['includeProjects'] = 'true'
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      data = {workbooks: []}
      doc = Nokogiri::XML(resp.body)
      doc.css("tsResponse workbooks workbook").each do |w|
        workbook = {id: w["id"], name: w["name"]}

        if params[:get_thumbnails]
          workbook["image"] = @client.conn.get("/api/2.0/sites/#{site_id}/workbooks/#{w['id']}/previewImage").body
          # workbook["view_name"] = Nokogiri::XML(http_request("/api/2.0/sites/#{@site_id}/workbooks/#{wb['id']}/views", nil, "get").body).css("tsResponse views view").first[:name]
        end

        data[:workbooks] << workbook
      end
      data.to_json
    end



  end
end