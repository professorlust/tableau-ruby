module Tableau
  class Workbook

    def self.all(get_thumbnails=false)
      resp = http_request("/api/2.0/sites/#{@site_id}/users/#{@user_id}/workbooks", nil, "get")
      if resp.status == 200
        workbooks = Hash.from_xml(Nokogiri::XML(resp.body).css("tsResponse workbooks").to_s)["workbooks"]["workbook"]
        if get_thumbnails
          workbooks.each do |wb|
            wb["image"] = http_request("/api/2.0/sites/#{@site_id}/workbooks/#{wb['id']}/previewImage", nil, "get").body
            wb["view_name"] = Nokogiri::XML(http_request("/api/2.0/sites/#{@site_id}/workbooks/#{wb['id']}/views", nil, "get").body).css("tsResponse views view").first[:name]
          end
        else
          workbooks
        end
      else
        nil
      end
    end

  end
end