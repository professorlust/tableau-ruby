# TableauRuby

Unofficial Tableau API Ruby client

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tableau_ruby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tableau_ruby

## Usage

### Setup

``` ruby
require 'rubygmes'
require 'tableau_ruby'

Tableau.configure do |config|
	# Required
	config.host = 'https://your-url-here.com'
	config.username = 'your-admin-username'
	config.password = 'your-admin-password'
	# Optional
	config.user_id = 'user-to-act-on-behalf-of'
	config.site_name = 'defaults-to-Default'
end

@client = Tableau::Client.new
```

### Sites
``` ruby

# By default the all request does not include projects in the results
# add them by including include_projects: true
@sites = client.sites.all(include_projects: true)
@site = client.sites.find_by(site_id: 'string-id') # also try site_name and site_url

@site = client.sites.create(name: 'Project Name')
@site = client.sites.update(site_id: 'site-id')
@site = client.sites.delete(site_id: 'site-id')

```

### Projects
``` ruby

@projects = @client.projects.all()

@project = client.projects.create(name: 'Project Name')
@project = client.projects.update(site_id: 'project-site-id', project_id: 'project-id')
@project = client.projects.delete(site_id: 'project-site-id', project_id: 'project-id')

```

### Users
``` ruby

@users = client.users.all(site_id: 'site-id')
@user = client.users.find_by(site_id: 'site-id', name: 'user-name')

@user = client.users.create(site_id: 'site-id', name: 'new user')
@user = client.users.delete(site_id: 'site-id', user_id: 'user-id')
```

### Workbooks
``` ruby

```

## TODO
* inherit site_id from client object to avoid having to pass site_id
* consolidate parameter checking
* error responses
* make self documenting

## Contributing

1. Fork it ( https://github.com/[my-github-username]/tableau_ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
