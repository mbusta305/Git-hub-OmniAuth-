# OmniAuth Code Along with RSpec

This code along activity will show you how to use the OmniAuth gem to add GitHub authentication to your app. This same process can be used for many of the most popular OAuth SSO (single-sign-on) providers.


## Step 0: Start with a Fresh Copy

Please open your terminal and head over your own work folder or location.

- ```git clone git@github.com:wyncode/student-resources.git   ```

- ``` cd /student-resources/omniauth_authentication_code_along_with_rspec/omniauth-github-code-along-starting-app```
 - ``` atom . ```

## Step 1: Dependencies

### Gemfile

We are going to use a gem called [omniauth-github](https://github.com/intridea/omniauth-github), which implements the OmniAuth _strategy_ for GitHub. Since OAuth providers may differ, OmniAuth uses different strategies for each provider.

Add this gem to your `Gemfile`
```ruby
# Gemfile
gem 'omniauth-github'
```

... and re-bundle
```sh
# terminal
bundle
```

## Step 2: Application Registration

To introduce your app to GitHub, you need to create an _application profile_ for it. Register a new application on your [GitHub Applications Page](https://github.com/settings/applications).

GitHub will generate your application's `Client ID` (aka _username_) and `Client Secret`) (aka _password_). Don't ever copy and paste these values into your code. They'll likely end up in a public GitHub repo for everyone to see.

Choose whatever `Application name` you'd like.

The `Homepage URL` is the URL you'd like users to visit to read more information about your app. Just use `http://localhost:3000`.

Leave the `Application description` blank.

The `Authorization callback URL` is the URL GitHub will redirect users to after they login. Use `http://localhost:3000/auth/github/callback`. [More details here](https://developer.github.com/guides/basics-of-authentication/#registering-your-app)

| Field | Value
| --- | ---
| Application Name | My Super Awesome Github OAuth App
| Homepage URL | http://localhost:3000
| Application description |
|  Authorization callback URL | http://localhost:3000/auth/github/callback

## Step 3: Configure OmniAuth

The `config/initializers` folder in Rails contains Ruby files that run when your server starts (during `rails s`). It's a common place to put configuration code that doesn't fit into Rail's default configuration files.

Let's create an initializer for OmniAuth

# Terminal
```
touch config/initializers/omniauth.rb
```


```ruby
# config/initializers/omniauth.rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], scope: "user:email"
end
```

Instead of copying our `CLIENT_ID` and `CLIENT_SECRET` into the app, we're using a reference to the `ENV` global variable, which pulls data stored in Bash variables in the Terminal.

The `scope` option defines what extra fields on the GitHub profile we want. In this example, we want the user's email (in addition to his `basic profile` information).

## Step 4: Configuring the Environment

The [12-Factor methodology](http://12factor.net/) advocates for a [strict separation of config from code](http://12factor.net/config).

Specifically, adding secrets to our GitHub repo is likely to make those secrets public.

One way to keep your configuration secret is to store your secret config in your Bash environment.

In the Terminal, your environment can be examined with the `env` command.
```sh
# Terminal
env
```

Values in the Terminal environment are available in your Ruby (and Rails) code via the global `Hash` `ENV`.
```ruby
# irb
ENV['USER']
```

You can add secrets to your environment in multiple ways.

### Profile Secrets

The easiest is to use your Terminal profile.

```
# Terminal
atom ~/.profile
```


```sh
# at the end of ~/.profile
export CLIENT_ID=my_client_id_value_goes_here
export CLIENT_SECRET=my_client_secret_value_goes_here
```

Since `~/.profile` only executes at the start of your Terminal session, either open a new Terminal tab or type `source ~/.profile` to load your new variables.

To confirm in the Terminal:
```sh
# Terminal
echo $CLIENT_ID $CLIENT_SECRET
```

To confirm in `irb`:
```ruby
# irb
p ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
```

### dotenv secrets

The [bkeepers/dotenv gem](https://github.com/bkeepers/dotenv) is another common way to store secrets in your app. If you decide to go this route, just add the gem to your Gemfile.( I already did it for you.)

At the end like this:
```ruby
# Gemfile
gem 'dotenv-rails', :groups => [:development, :test]
```

Or inside the existing code like this:
```ruby
# Gemfile
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'dotenv-rails'
end
```

Don't forget to rebundle!
```sh
# Terminal
bundle
```

The dotenv gem looks for secret env config in a file named `.env` in the root of your app.

```sh
# .env
CLIENT_ID=my_client_id_value_goes_here
CLIENT_SECRET=my_client_secret_value_goes_here
```

To confirm in `rails c`:
```ruby
# rails console
p ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
```

Git is going to detect `.env` as a new file and ask to if you want to add&commit it. You do not. Otherwise you'll share your secrets with the world.

Use `.gitignore` to tell Git to ignore `.env`.
```
# skip to the end of .gitignore

# Ignore all logfiles and tempfiles.
/log/*
!/log/.keep
/tmp

.env
```

## Step 5: The User Model

OmniAuth is ready to go, but we still need a place to store the data we get back from the OAuth provider.

Create a `User` model.
```sh
# Terminal
rails g model user name email provider uid
```

field | description
--- | ---
name | the user's name
email | the user's email address
provider | the OAuth provider's name (e.g. GitHub, Facebook, LinkedIn, etc.)
uid | the user's id on the provider (e.g. your Facebook user id)

The OAuth provider doesn't care about my internal ids. It doesn't care that my user has `id=1`. It will respond with its own internal ids. So we keep track of how the provider's id (`provider` and `uid`) maps to our own `User` `id` column.

Don't forget to create the database and migrate!
```sh
# Terminal
rake db:create && rake db:migrate && rake db:migrate RAILS_ENV=test
```

## Step 6: Creating a User with OmniAuth

We need to teach the `User` how to create an instance of itself using OmniAuth data.

```
# app/models/user.rb
class User < ActiveRecord::Base
  validates :provider, presence: true
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
    end
  end
end
```

OmniAuth will populate a `Hash` with data received from the OAuth provider.


## Step 7: Login/Logout via a  Sessions Controller

We're going to create a `SessionsController` to manage logging into and out of our app.

```sh
# Terminal
rails g controller sessions --no-controller-specs
```

Define `create` and `destroy` actions in the new controller.
```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  # login
  def create
    # omniauth stores data in the request.env instead of params
    auth = request.env["omniauth.auth"]

    # even though this is a login action, an OAuth login can be a login *or* a registration
    #
    # if the user exists, log her in
    # if the user doesn't exist, create her, then log her in
    user =
      User.find_by(provider: auth['provider'], uid: auth['uid']) ||
      User.create_with_omniauth(auth)

    session[:user_id] = user.id
    redirect_to root_url, notice: "Signed in!"
  end

  # logout
  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: "Signed out!"
  end
end
```

## Step 8: "current_user" Helper

To make it easy to get the currently logged-in user, create a "current_user" helper in your "ApplicationController".

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  private

  # make this method accessible in any controller
  def current_user
    # memoization (caching) technique
    # multiple calls to this method will result in only one database query
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  # make this method acccessible in any view
  helper_method :current_user
end
```

## Step 9: Create a View

Generate a page we can use to test all this stuff.

 Terminal
```
rails g controller users new
```

Update the generated placeholder view located at:  "app/views/new.html.erb"

with:  
```
<%# app/views/new.html.erb %>
<em><%= notice %></em><br>
<% if current_user %>
  Welcome <%= current_user.name %> you have successfully signed in!<br>
  <%= link_to "Sign out", logout_path %>
<% else %>
  You are so not signed in.<br>
  <%= link_to "Sign in with Github", github_login_path %><br>
<% end %>
```

## Step 10: Routes
  We need to define some routes to connect all these pieces together

```
# config/routes.rb
root 'users#new'
get 'users/new'

get 'auth/:provider/callback' => 'sessions#create'
get 'auth/github', as: 'github_login'

get 'logout' => 'sessions#destroy'
```

## Step 11: Test it out  

Start your server
```
# Terminal
rails s
```

Visit [http://localhost:3000/](http://localhost:3000/).

If everything works, (and there are no typos!), you should be able to sign in and out with GitHub.

The first time you sign in with GitHub, GitHub will ask if you're ok with allowing this application to access your private profile information. If you're ok with that, you'll be redirected back to your Rails app where you should see a successful sign on page.

## Your Turn

We didn't save the user'e email address into our `User` model. Update this app to store the `email` address from GitHub.

Try to run rspec spec. All test should be green.


