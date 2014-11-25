module Tableau
  class User

    def initialize(client, user)
      @client = client
    end

    # def sign_out
    #   http_request("/auth/signout", nil, "post")
    # end

    # def all
    #   http_request("/sites/#{@site_id}/users/", nil, "get")
    # end

  end
end