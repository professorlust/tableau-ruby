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
      options[:site_id] = @site_id
      options[:user_id] = @id

      @client.workbooks.all(options)
    end

  end
end