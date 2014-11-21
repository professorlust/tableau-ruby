module Tableau
  class User

    def all
      http_request("/sites/#{@site_id}/users/", nil, "get")
    end

  end
end