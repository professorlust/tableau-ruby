module Tableau
  class Site

    def initialize(client)
      @client = client
    end

    def all(params={includeProjects: true})
      resp = @client.conn.get "/api/2.0/sites" do |req|
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      data = {sites: []}
      Nokogiri::XML(resp.body).css("tsResponse sites site").each do |s|
        s.css("project").each do |p|
          (@projects ||= []) << {id: p["id"], name: p["name"]}
        end
        data[:sites] << {
          name: "#{s['name']}",
          id: "#{s['id']}",
          content_url: "#{s['contentUrl']}",
          admin_mode: "#{s['adminMode']}",
          user_quota: "#{s['userQuota']}",
          storage_quota: "#{s['storageQuota']}",
          state: "#{s['state']}",
          status_reason: "#{s['statusReason']}",
          projects: @projects
        }
      end
      data.to_json
    end

    def find_by_id(site_id, params={})
      return { error: "site_id is missing." }.to_json unless site_id.nil? || site_id.blank?

      resp = @client.conn.get "/api/2.0/sites/#{site_id}" do |req|
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      normalize_json(resp.body)
    end

    def find_by_site_name(site_name, params={})
      resp = @client.conn.get "/api/2.0/sites/#{site_name}" do |req|
        req.params["key"] = "name"
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      normalize_json(resp.body)
    end

    def find_by_site_url_namespace(site_url_namespace, params={})
      resp = @client.conn.get "/api/2.0/sites/#{site_url_namespace}" do |req|
        req.params["key"] = "contentUrl"
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      normalize_json(resp.body)
    end

    def create(site_object)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.site(
            name: site_object[:name] || 'New Site',
            contentUrl: site_object[:content_url],
            adminMode: site_object[:admin_mode] || 'ContentAndUsers',
            userQuota: site_object[:user_quota] || '100',
            storageQuota: site_object[:storage_quota] || '20',
            disableSubscriptions: site_object[:disable_subscriptions] || false
          )
        end
      end

      resp = @client.conn.post "/api/2.0/sites" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      if resp.status == 201
        normalize_json(resp.body)
      else
        {error: resp.status}.to_json
      end
    end

    def update(site_object)
      return { error: "site_id is missing." }.to_json unless site_object[:site_id]

      case_dict = {
        name: "name",
        content_url: "contentUrl",
        admin_mode: "adminMode",
        user_quota: "userQuota",
        storage_quota: "storageQuota",
        disable_subscriptions: "disableSubscriptions"
      }

      site_object.each do |k,v|
        next if k == :site_id
        (@site ||= {}).store(case_dict[k],v)
      end

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.site(@site)
        end
      end

      resp = @client.conn.put "/api/2.0/sites/#{site_object[:site_id]}" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      normalize_json(resp.body)
    end

    def delete(site_object)
      return { error: "site_id is missing." }.to_json unless site_object[:site_id]

      resp = @client.conn.delete "/api/2.0/sites/#{site_object[:site_id]}" do |req|
        params.each {|k,v| req.params[k] = v}
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      normalize_json(resp.body)
    end

    private

    def normalize_json(r)
      data = {}
      Nokogiri::XML(r).css("tsResponse site").each do |s|
        data[:site] = {
          name: "#{s['name']}",
          id: "#{s['id']}",
          content_url: "#{s['contentUrl']}",
          admin_mode: "#{s['adminMode']}",
          user_quota: "#{s['userQuota']}",
          storage_quota: "#{s['storageQuota']}",
          state: "#{s['state']}",
          status_reason: "#{s['statusReason']}"
        }
      end
      data.to_json
    end
  end
end