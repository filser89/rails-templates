run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
gsub_file('Gemfile', 'source \'https://rubygems.org\'', '')
add_source 'https://gems.ruby-china.com'
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
  gem 'devise'
  gem 'autoprefixer-rails', '10.2.5'
  gem 'font-awesome-sass'
  gem 'simple_form'

  # For API calls
  gem 'rest-client'

  # Use Active Storage variant
  gem 'image_processing', '~> 1.2'

  # Alicloud storage
  gem 'activestorage-aliyun'

  # background jobs processing
  gem 'sidekiq'
  gem 'sidekiq-failures', '~> 1.0'

  # authentication
  gem 'jwt'

  # handle money
  gem 'money-rails', '~>1.12'

  # models translation
  gem 'json_translate'
  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY
  gem 'pry-byebug'
  gem 'pry-rails'
  RUBY
end

inject_into_file 'Gemfile', after: 'group :development do' do
  <<-RUBY
  # kill n+1 queries
  gem 'bullet'
  RUBY
end

gsub_file('Gemfile', /# gem 'redis'/, "gem 'redis'")

# Assets
########################################
run 'rm -rf app/assets/stylesheets'
run 'rm -rf vendor'
run 'curl -L https://github.com/lewagon/rails-stylesheets/archive/master.zip > stylesheets.zip'
run 'unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets'

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
if Rails.version < "6"
  scripts = <<~HTML
  <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
  <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
  HTML
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>", scripts)
end

gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")

style = <<~HTML
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)

# Flashes
########################################
file 'app/views/shared/_flashes.html.erb', <<~HTML
<% if notice %>
<div class="alert alert-info alert-dismissible fade show m-1" role="alert">
<%= notice %>
<button type="button" class="close" data-dismiss="alert" aria-label="Close">
<span aria-hidden="true">&times;</span>
</button>
</div>
<% end %>
<% if alert %>
<div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
<%= alert %>
<button type="button" class="close" data-dismiss="alert" aria-label="Close">
<span aria-hidden="true">&times;</span>
</button>
</div>
<% end %>
HTML

run 'curl -L https://github.com/lewagon/awesome-navbars/raw/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb'

inject_into_file 'app/views/layouts/application.html.erb', after: '<body>' do
  <<-HTML
  <%= render 'shared/navbar' %>
  <%= render 'shared/flashes' %>
  HTML
end

# README
########################################
markdown_file_content = <<-MARKDOWN
##Gems Setup:
- Authentication with **devise**
- Authentication with **jwt**
- Background jobs with **sidekiq**
- API calls with **rest-client**
- Handle money and currencies with **money-rails**. Default currency: ***CNY***
- Model translations with **json_translate**. Locales: :en, :cn
- Active Storage with **activestorage-aliyun**
## Credentials set-up
#### In order to use this template set up the following values in config/credentials.yml.enc
```yaml
  wx_mp:
    app_id: [YOUR-Mini-Program-APP-ID (provided by WECHAT)]
    app_secret: [YOUR-Mini-Program-APP-SECRET (provided by WECHAT)]
  aliyun_oss:
    access_key_id: [YOUR-ALIYUN-KEY-ID]
    access_key_secret: [YOUR-ALIYUN-KEY-SECRET]
    bucket_name: [YOUR-ALIYUN-BUCKET-NAME (set by you when creating a bucket)]
    endpoint: https://oss-cn-shanghai.aliyuncs.com (depends on your bucket location)
  api_key: [YOUR-API-KEY]
  jwt:
    token_secret_key: [YOUR-JWT-TOKEN]
    expiration: [TOKEN-EXPIRATION-IN-SECONDS (Recommended: 900)]
  ```
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<~RUBY
config.generators do |generate|
  generate.assets false
  generate.helper false
  generate.test_framework :test_unit, fixture: false
end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Get resources
  ########################################
  run 'curl -L https://github.com/filser89/rails-wxmp-setup-resourses/archive/master.zip > resources.zip'
  run 'unzip resources.zip && rm resources.zip && mv rails-wxmp-setup-resourses-master resources'

  # Add services
  ########################################
  run 'mv resources/services app/services'

  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # Rails money config
  ########################################
  generate('money_rails:initializer')
  gsub_file('config/initializers/money.rb', /# config.default_currency = :usd/, "config.default_currency = :cny")

  # locales config
  ########################################
  file 'config/initializers/locale.rb', <<~RUBY
  I18n.default_locale = :en
  I18n.available_locales = [:en, 'zh-CN']
  RUBY

  run 'rm  config/locales/en.yml'
  run 'mv resources/locales/en.yml config/locales/en.yml'
  run 'mv resources/locales/cn.yml config/locales/cn.yml'

  environment 'config.i18n.fallbacks = true', env: 'development'

  # sidekiq as job adapter
  ########################################
  environment 'config.active_job.queue_adapter = :sidekiq', env: 'development'
  run 'mv resources/workers app/workers'

  # Aliyun
  ########################################
  rails_command 'active_storage:install'
  run 'rm config/storage.yml'

  if Rails.version < "6.1"
    settings = <<~YAML
    test:
      service: Disk
    \s\sroot: <%= Rails.root.join("tmp/storage") %>

    local:
      service: Disk
    \s\sroot: <%= Rails.root.join("storage") %>

    aliyun:
      service: Aliyun
    \s\saccess_key_id: <%= Rails.credentials.dig(:aliyun_oss, :access_key_id) %>
    \s\saccess_key_secret: <%= Rails.credentials.dig(:aliyun_oss, :access_key_secret) %>
    \s\sbucket: <%= Rails.credentials.dig(:aliyun_oss, :bucket) %>
    \s\sendpoint: <%= Rails.credentials.dig(:aliyun_oss, :endpoint) %>
    \s\s# Bucket mode: [public, private], default: public
    \s\smode: "private"
    YAML
  else
    settings = <<~YAML
    test:
      service: Disk
    \s\sroot: <%= Rails.root.join("tmp/storage") %>

    local:
      service: Disk
    \s\sroot: <%= Rails.root.join("storage") %>

    aliyun:
      service: Aliyun
    \s\saccess_key_id: <%= Rails.credentials.dig(:aliyun_oss, :access_key_id) %>
    \s\saccess_key_secret: <%= Rails.credentials.dig(:aliyun_oss, :access_key_secret) %>
    \s\sbucket: <%= Rails.credentials.dig(:aliyun_oss, :bucket) %>
    \s\sendpoint: <%= Rails.credentials.dig(:aliyun_oss, :endpoint) %>
    \s\spublic: false
    YAML
  end
  file 'config/storage.yml', settings

  gsub_file('config/environments/development.rb', /config\.active_storage\.service.*/, 'config.active_storage.service = :aliyun')
  gsub_file('config/environments/production.rb', /config\.active_storage\.service.*/, 'config.active_storage.service = :aliyun')

  # Routes
  ########################################
  route "root to: 'pages#home'"
  route <<~RUBY
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      post 'users/wx_login', to: 'users#wx_login'
    end
  end
  RUBY

  # Git ignore
  ########################################
  append_file '.gitignore', <<~TXT

  # Ignore Mac and Linux file system files
  *.swp
  .DS_Store
  TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User mp_openid:string mp_session_key:string unionid:string')

  #Controlles
  ########################################
  run 'rm -rf app/controllers'
  run 'mv resources/controllers app/controllers'

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'


  # Webpacker / Yarn
  ########################################
  run 'yarn add popper.js jquery bootstrap@4.6'
  append_file 'app/javascript/packs/application.js', <<~JS
  // ----------------------------------------------------
    // Note(lewagon): ABOVE IS RAILS DEFAULT CONFIGURATION
  // WRITE YOUR OWN JS STARTING FROM HERE 👇
  // ----------------------------------------------------
    // External imports
  import "bootstrap";
  // Internal imports, e.g:
    // import { initSelect2 } from '../components/init_select2';
  document.addEventListener('turbolinks:load', () => {
                              // Call your functions here, e.g:
                              // initSelect2();
  });
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
    <<~JS
    const webpack = require('webpack');
    // Preventing Babel from transpiling NodeModules packages
    environment.loaders.delete('nodeModules');
    // Bootstrap 4 has a dependency over jQuery & Popper.js:
      environment.plugins.prepend('Provide',
                                  new webpack.ProvidePlugin({
                                                              $: 'jquery',
                                                              jQuery: 'jquery',
                                                              Popper: ['popper.js', 'default']
                                  })
                                  );
    JS
  end

  # Rubocop
  ########################################
  run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Remove resources folder
  ########################################
  run 'rm -rf resources'

  # Git
  ########################################
  git add: '.'
  git commit: "-m 'Initial commit with rails-wxmp-setup config'"

  # Fix puma config
  gsub_file('config/puma.rb', 'pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }', '# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }')
end
