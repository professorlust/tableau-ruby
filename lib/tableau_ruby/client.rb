module Tableau
  class Client
    attr_reader :conn, :host, :projects, :sites, :site_id, :site_name, :token, :users, :user_id, :workbooks

    #{username, user_id, password, site}
    def initialize(args={})
      @host = args[:host] || Tableau.host
      @username = args[:username] || Tableau.username
      @password = args[:password] || Tableau.password
      @site_name = args[:site_name] || "Default"

      setup_connection

      @token = sign_in
      @site_id = get_site_id
      @user_id = args[:user_id].nil? ? nil : get_user_id

      setup_subresources
    end

    def inspect
      "<Tableau::Client @host=#{@host} @username=#{@username} @site_name=#{@site_name} @site_id=#{@site_id} @user_id=#{@user_id}>"
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
      @users     = Tableau::Users.new(self)
      @projects  = Tableau::Project.new(self)
      @sites     = Tableau::Site.new(self)
      @workbooks = Tableau::Workbook.new(self)
    end

    def setup_connection
      @conn = Faraday.new(url: @host) do |f|
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
    def sign_in
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.credentials(name: @username, password: @password) do
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
        return Nokogiri::XML(resp.body).css("tsResponse users user[name='#{@username}']").first[:id]
      else
        nil
      end
    end

  end
end
