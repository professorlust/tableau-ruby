module Tableau
  class Client
    attr_reader :conn, :projects, :sites, :site_id, :site_name, :token, :users, :user_id, :workbooks

    #{username, user_id, password, site}
    def initialize(user)
      @user_creds = user
      @site_name = user[:site_name] || "Default"

      setup_connection

      @token = sign_in(user)
      @site_id = get_site_id
      @user_id = user[:user_id].nil? ? nil : get_user_id

      setup_subresources
    end

    ##
    # Delegate user methods from the client. This saves having to call
    # <tt>client.user</tt> every time for resources on the default
    # user.
    def method_missing(method_name, *args, &block)
      if user.respond_to?(method_name)
        user.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to?(method_name, include_private=false)
      if user.respond_to?(method_name, include_private)
        true
      else
        super
      end
    end

    private

    def setup_subresources
      @users     = Tableau::User.new(self)
      @projects  = Tableau::Project.new(self)
      @sites     = Tableau::Site.new(self)
      @workbooks = Tableau::Workbook.new(self)
    end

    def setup_connection
      @conn = Faraday.new(url: "https://tabdev.traxtech.com") do |f|
        f.request :url_encoded
        f.response :logger
        f.adapter Faraday.default_adapter
        f.headers['Content-Type'] = 'application/xml'
      end
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
      resp = @conn.post do |req|
        req.url "/api/2.0/auth/signin"
        req.body = builder.to_xml
      end
      if resp.status == 200
        return Nokogiri::XML(resp.body).css("tsResponse credentials").first[:token]
      else
        raise ""
      end
    end

    def get_site_id
      resp = @conn.get "/api/2.0/sites/#{@site_name.gsub(' ', '%20')}" do |req|
        req.params['key'] = 'name'
        req.headers['X-Tableau-Auth'] = @token if @token
      end
      if resp.status == 200
        return Nokogiri::XML(resp.body).css("tsResponse site").first[:id]
      else
        nil
      end
    end

    def get_user_id
      resp = @conn.get "/api/2.0/sites/#{@site_id}/users/" do |req|
        req.headers['X-Tableau-Auth'] = @token if @token
      end

      puts resp.body

      if resp.status == 200
        return Nokogiri::XML(resp.body).css("tsResponse users user[name='#{@user_creds[:user_id]}']").first[:id]
      else
        nil
      end
    end

  end
end
