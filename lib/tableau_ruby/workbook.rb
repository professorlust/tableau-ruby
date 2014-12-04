require 'base64'

module Tableau
  class Workbook

    def initialize(client)
      @client = client
    end

    def all(params={})
      return { error: "site_id is missing." }.to_json if params[:site_id].nil? || params[:site_id].empty?

      resp = @client.conn.get "/api/2.0/sites/#{params[:site_id]}/users/#{user_id}/workbooks" do |req|
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      data = {workbooks: []}
      doc = Nokogiri::XML(resp.body)
      doc.css("tsResponse workbooks workbook").each do |w|
        workbook = {id: w["id"], name: w["name"]}

        if params[:get_thumbnails]
          resp = @client.conn.get("/api/2.0/sites/#{params[:site_id]}/workbooks/#{w['id']}/previewImage") do |req|
            req.headers['X-Tableau-Auth'] = @client.token if @client.token
          end
          workbook["image"] = Base64.encode64(resp.body)
          workbook["image_mime_type"] = "image/png"
        end

        data[:workbooks] << workbook
      end
      data.to_json
    end

    def find(workbook)
      resp = @client.conn.get "/api/2.0/sites/#{workbook[:site_id]}/workbooks/#{workbook[:workbook_id]}}" do |req|
        req.params['previewImage'] = params[:preview_images] || true
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {}
      Nokogiri::XML(r).css("workbook").each do |w|
        data[:site] = {
          name: "#{w['name']}",
          id: "#{w['id']}",
          description: "#{w['description']}"
        }
      end
      data.to_json

    end

  end
end