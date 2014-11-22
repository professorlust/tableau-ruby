module Tableau
  class Session
    API_URL = "https://tabdev.traxtech.com/api/2.0/"
    attr_accessor :site_id, :user_id, :token, :user

    #{username, user_id, password, site}
    def initialize(user)
      @user = user
      @site_name = user[:site_name] || "Default"
      @token = sign_in(user)
      @site_id = get_site_id
      @user_id = get_user_id
    end

    # <tsRequest>
    #   <credentials name="<username>" password="<password>" >
    #     <site contentUrl="" />
    #   </credentials>
    # </tsRequest>
    def sign_in(user)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.credentials(name: user[:username], password: user[:password]) do
            #xml.user(id: @user[:user_id])
            xml.site
          end
        end
      end
      resp = http_request("/auth/signin", builder.to_xml, "post")
      if resp.status == 200
        return Nokogiri::XML(resp.body).css("tsResponse credentials").first[:token]
      else
        nil
      end
    end

    def sign_out
      http_request("/auth/signout", nil, "post")
    end

    def get_site_id
      resp = http_request("/sites/#{@site_name.gsub(' ', '%20')}?key=name",nil,"get")
      if resp.status == 200
        return Nokogiri::XML(resp.body).css("tsResponse site").first[:id]
      else
        nil
      end
    end

    def get_user_id
      resp = http_request("/sites/#{@site_id}/users/", nil, "get")
      if resp.status == 200
        return Nokogiri::XML(resp.body).css("tsResponse users user[name='#{@user[:user_id]}']").first[:id]
      else
        nil
      end
    end

    private

    def http_request(path, payload, method, token=nil)
      Faraday.send(method) do |request|
        request.url  API_URL+path
        request.headers['Content-Type'] = 'application/xml'
        request.headers['X-Tableau-Auth'] = @token if @token
        request.body = payload
      end
    end

  end
end
