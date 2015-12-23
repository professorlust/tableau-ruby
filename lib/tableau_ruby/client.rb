require 'uri'

module Tableau
  class Client
    attr_reader :conn, :host, :admin_name, :projects, :sites, :site_id, :site_name, :token, :user, :users, :workbooks

    #{username, user_id, password, site}
    def initialize(args={})
      @host = args[:host] || Tableau.host
      @admin_name = args[:admin_name] || Tableau.admin_name
      @admin_password = args[:admin_password] || Tableau.admin_password
      @site_name = args[:site_name] || ""

      setup_connection

      @token = sign_in
      @site_id = get_site_id

      # Intentionally overwriting the token with the impersonated user's token
      @token = sign_in(args[:user_name]) if args[:user_name]

      setup_subresources
    end

    def inspect
      "<Tableau::Client @host=#{@host} @admin_name=#{@admin_name} @site_name=#{@site_name} @site_id=#{@site_id} @user=#{@user}>"
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

    def sign_in(user=nil)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.credentials(name: @admin_name, password: @admin_password) do
            xml.site(contentUrl: @site_name.gsub(' ', ''))
          end
        end
      end

      resp = @conn.post do |req|
        req.url "/api/2.1/auth/signin"
        req.body = builder.to_xml
      end

      if resp.status == 200
        if user
          @users = Tableau::Users.new(self)
          @user = Tableau::User.new(self, JSON.parse(@users.find_by(site_id: @site_id, name: user))['user'])
          impersonate(@user)
        else
          return Nokogiri::XML(resp.body).css("credentials").first[:token]
        end
      else
        raise ArgumentError, Nokogiri::XML(resp.body)
      end
    end

    def impersonate(user)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.credentials(name: @admin_name, password: @admin_password) do
            xml.user(id: user.id) if user
            xml.site(contentUrl: @site_name.gsub(' ', ''))
          end
        end
      end

      resp = @conn.post do |req|
        req.url "/api/2.1/auth/signin"
        req.body = builder.to_xml
      end

      if resp.status == 200
        return Nokogiri::XML(resp.body).css("credentials").first[:token]
      else
        raise ArgumentError, Nokogiri::XML(resp.body)
      end
    end

    def get_site_id
      resp = @conn.get "/api/2.1/sites/#{URI.encode(@site_name)}/" do |req|
        req.params['key'] = 'name'
        req.headers['X-Tableau-Auth'] = @token if @token
      end

      if resp.status == 200
        return Nokogiri::XML(resp.body).css("site").first[:id]
      else
        puts resp.inspect
      end
    end

  end
end
