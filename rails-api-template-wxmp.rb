run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"
# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY
  gem 'autoprefixer-rails'
  gem 'sidekiq'
  gem 'sidekiq-failures', '~> 1.0'
  gem 'redis'
  gem 'httparty' # HTTP requests, API calls
  gem 'jwt' #authentication

  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY

  gem 'pry-byebug'
  gem 'pry-rails'
  RUBY
end
gsub_file 'Gemfile', "source 'https://rubygems.org'", "source 'https://gems.ruby-china.com'"
gsub_file 'Gemfile', "gem 'webpacker', '~> 4.0'", ''
gsub_file 'Gemfile', "gem 'turbolinks', '~> 5'", ''
gsub_file 'Gemfile', "gem 'jbuilder', '~> 2.7'", ''
gsub_file 'Gemfile', "gem 'sass-rails', '>= 6'", ''

# Procfile
########################################
file 'Procfile', <<~YAML
web: bundle exec puma -C config/puma.rb
YAML

# Remove Assets
########################################
run 'rm -rf app/assets/stylesheets'
run 'rm -rf vendor'

# Remove views
########################################
run 'rm app/views/layouts/application.html.erb'

# Remove unnecessary folders from app
run 'rm -rf app/helpers'
run 'rm -rf app/javascript'

# Clear Public directory
########################################
run 'rm public/*'
# README
########################################
markdown_file_content = <<~MARKDOWN
Rails API for WeChat MiniPrograms.

  ## Credentials set-up
  #### In order to use this template set up the following values in config/credentials.yml.enc

  api_key: [YOUR-API-KEY]
jwt_token_secret_key: [YOUR-JWT-TOKEN]
jwt_expiration_seconds: [TOKEN-EXPIRSTION-IN-SECONDS (Recommended: 900)]
wx_mp_app_id: [YOUR-APP-ID (provided by WECHAT)]
wx_mp_app_secret: [YOUR-APP-SECRET (provided by WECHAT)]

## API
- each API call must include API-Key in request headers
- only /api/v1/users/wx_login do not need X-Auth-Token in request headers
  - after wx_login, user returned with an auto_token, after that, every API request will include the auth_token in header as X-Auth-Token
  - the auth_token used to indentify a user from DB, in each controlers the method current_user is the user made the API request
  - User has a instance method #token to generate a token for test, User.first.token => token string

  ## Architecture
  MVC S
  - S is service: wechat open id, token. Defined in app/services
  - It is recommended to directlly render json in controllers, with two instance methods in model return hash for json format, Model#index_hash, Model#show_hash (see app/models/user.rb for reference)
  - Change the #index_hash and #show_hash methods OR add more similar methods to return the data needed in MP


  MARKDOWN
  file 'README.md', markdown_file_content, force: true

  # API only
  ########################################
  environment 'config.api_only = true'

  ########################################
  # AFTER BUNDLE
  ########################################
  after_bundle do

    # Gemfile.lock
    ########################################
    gsub_file 'Gemfile.lock', "remote: https://rubygems.org/", "remote: https://gems.ruby-china.com/"

    # DB
    ########################################
    rails_command 'db:drop db:create db:migrate'

    # User Model
    #######################################
    generate(:model, 'user', 'name', 'city', 'wechat', 'phone', 'email', 'gender', 'admin:boolean', 'wx_open_id', 'wx_session_key')
    generate 'migration SetDefaultsToUsersAttributes'
    dir = 'db/migrate'
    migration_files_array = Dir.entries(dir)
    file = migration_files_array.find {|f| f.match('set_defaults_to_users_attributes.rb')}
    file_dir = "#{dir}/#{file}"
    inject_into_file file_dir, after: "def change\n" do
      <<~RUBY
      change_column_default :users, :city, nil
      change_column_default :users, :wechat, nil
      change_column_default :users, :phone, nil
      change_column_default :users, :email, nil
      change_column_default :users, :gender, nil
      change_column_default :users, :admin, false
      change_column_default :users, :wx_open_id, nil
      change_column_default :users, :wx_session_key, nil
      RUBY
    end
    rails_command 'db:migrate'
    run 'rm -rf app/models/user.rb'
    run 'curl -L https://github.com/filser89/rails-wxmp-setup-resourses/archive/master.zip > resources.zip'
    run 'unzip resources.zip && rm resources.zip && mv rails-api-template-wxmp-resources-master/user.rb app/models/user.rb'

    # Routes
    # ########################################
    user_routes = <<~RUBY
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        resources :users, only: [:index, :show] do
          collection do
            post :wx_login
          end
        end
      end
    end
    RUBY
    route user_routes

    # Controller
    # ########################################
    run 'rm -rf app/controllers'
    run 'mv rails-api-template-wxmp-resources-master/controllers app/controllers'

    # Services
    # ########################################
    run 'mv rails-api-template-wxmp-resources-master/services app/services'

    # Locales
    # ########################################
    run 'rm -rf config/locales'
    run 'mv rails-api-template-wxmp-resources-master/locales config/locales'

    # Remove resources folder
    ########################################
    run 'rm -rf rails-api-template-wxmp-resources-master'

    # Git ignore
    ########################################
    gsub_file '.gitignore', '/.bundle', 'api/.bundle'
    gsub_file '.gitignore', '/log/*', 'api/log/*'
    gsub_file '.gitignore', '/tmp/*', 'api/tmp/*'
    gsub_file '.gitignore', '/storage/*', 'api/storage/*'
    gsub_file '.gitignore', '/config/master.key', 'api/config/master.key'
    append_file '.gitignore', <<~TXT
    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
    TXT

    # Directories setup
    ########################################
    run 'mkdir ../api && mv ./* ../api && mv ../api . && mv .ruby-version api/.ruby-version'

    # Git
    ########################################
    git add: '.'
    git commit: "-m 'Initial commit'"
  end
