require 'base64'

module Tableau
  class Workbook

    def initialize(client)
      @client = client
    end

    def all(params={})
      return { error: "site_id is missing." }.to_json if params[:site_id].nil? || params[:site_id].empty?

      resp = @client.conn.get "/api/2.0/sites/#{params[:site_id]}/users/#{params[:user_id]}/workbooks" do |req|
        req.params['getThumbnails'] = params[:get_thumbnails] if params[:get_thumbnails]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      data = {workbooks: []}
      Nokogiri::XML(resp.body).css("workbook").each do |w|
        workbook = {id: w["id"], name: w["name"]}

        if params[:get_thumbnails]
          resp = @client.conn.get("/api/2.0/sites/#{params[:site_id]}/workbooks/#{w['id']}/previewImage") do |req|
            req.headers['X-Tableau-Auth'] = @client.token if @client.token
          end
          workbook["image"] = Base64.encode64(resp.body)
          workbook["image_mime_type"] = "image/png"
        end

        if params[:include_views]
          wkbk[:views] = include_views(site_id: params[:site_id], workbook_id: w['id'])
        end

        data[:workbooks] << workbook
      end
      data.to_json
    end

    def find(workbook)
      resp = @client.conn.get "/api/2.0/sites/#{workbook[:site_id]}/workbooks/#{workbook[:workbook_id]}" do |req|
        req.params['previewImage'] = workbook[:preview_images] if workbook[:preview_images]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {workbook: {}}
      Nokogiri::XML(resp.body).css("workbook").each do |w|

        wkbk = {id: w["id"], name: w["name"], description: w['description']}

        if workbook[:include_views]
          wkbk[:views] = include_views(site_id: workbook[:site_id], workbook_id: workbook[:workbook_id])
        end

        data[:workbook] = wkbk
      end

      data.to_json

    end

    private

    def include_views(params)
      resp = @client.conn.get("/api/2.0/sites/#{params[:site_id]}/workbooks/#{params[:workbook_id]}/views") do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      Nokogiri::XML(resp.body).css("view").each do |v|
        (@views ||= []) << {id: v['id'], name: v['name']}
      end

      @views
    end

  end
end