require 'base64'

module Tableau
  class Workbook

    def initialize(client)
      @client = client
    end

    def all(params={})
      return { error: "site_id is missing." }.to_json if params[:site_id].nil? || params[:site_id].empty?
      return { error: "user_id is missing." }.to_json if params[:user_id].nil? || params[:user_id].empty?

      resp = @client.conn.get "/api/2.0/sites/#{params[:site_id]}/users/#{params[:user_id]}/workbooks" do |req|
        req.params['getThumbnails'] = params[:include_images] if params[:include_images]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {workbooks: [], pagination: {}}
      doc = Nokogiri::XML(resp.body)

      doc.css("pagination").each do |p|
        data[:pagination][:page_number] = p['pageNumber']
        data[:pagination][:page_size] = p['pageSize']
        data[:pagination][:total_available] = p['totalAvailable']
      end

      doc.css("workbook").each do |w|
        workbook = {id: w["id"], name: w["name"]}

        if params[:include_images]
          resp = @client.conn.get("/api/2.0/sites/#{params[:site_id]}/workbooks/#{w['id']}/previewImage") do |req|
            req.headers['X-Tableau-Auth'] = @client.token if @client.token
          end
          workbook[:image] = Base64.encode64(resp.body)
          workbook[:image_mime_type] = "image/png"
        end

        w.css('project').each do |p|
          workbook[:project] = {id: p['id'], name: p['name']}
        end

        w.css("tag").each do |t|
          workbook[:tags] << t['id']
        end

        if params[:include_views]
          workbook[:views] = include_views(site_id: params[:site_id], id: w['id'])
        end

        data[:workbooks] << workbook
      end
      data.to_json
    end

    def find(workbook)
      resp = @client.conn.get "/api/2.0/sites/#{workbook[:site_id]}/workbooks/#{workbook[:id]}" do |req|
        req.params['previewImage'] = workbook[:preview_images] if workbook[:preview_images]
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {workbook: {}}
      Nokogiri::XML(resp.body).css("workbook").each do |w|

        wkbk = {id: w["id"], name: w["name"], description: w['description']}

        if workbook[:include_views]
          wkbk[:views] = include_views(site_id: workbook[:site_id], id: workbook[:id])
        end

        data[:workbook] = wkbk
      end

      data.to_json

    end

    private

    def include_views(params)
      resp = @client.conn.get("/api/2.0/sites/#{params[:site_id]}/workbooks/#{params[:id]}/views") do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      Nokogiri::XML(resp.body).css("view").each do |v|
        (@views ||= []) << {id: v['id'], name: v['name']}
      end

      @views
    end

  end
end