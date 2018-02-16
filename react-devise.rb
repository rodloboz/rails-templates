run 'pgrep spring | xargs kill -9'

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'
gem 'devise'
gem 'figaro'
gem 'jbuilder', '~> 2.0'
gem 'pg', '~> 0.21'
gem 'puma'
gem 'rails', '#{Rails.version}'
gem 'redis'
gem 'uglifier'
gem 'webpacker'
group :development do
  gem 'web-console', '>= 3.3.0'
end
group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
RUBY

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

# Procfile
########################################
file 'Procfile', <<-YAML
server: bin/rails server
assets: bin/webpack-dev-server
YAML

# Spring conf file
########################################
inject_into_file 'config/spring.rb', before: ').each { |path| Spring.watch(path) }' do
  '  config/application.yml\n'
end

# Browsers conf file
########################################
file '.browserslistrc', <<-TXT
> 1%
TXT

# Assets
########################################
run 'rm -rf app/assets'

# Packages
########################################
file 'package.json', <<-JSON
{
  "name": "app",
  "private": true,
  "dependencies": {
    "@rails/webpacker": "^3.2.2",
    "actioncable": "^5.1.5",
    "babel-preset-react": "^6.24.1",
    "coffeescript": "1.12.7",
    "normalize.css": "^7.0.0",
    "postcss-nested": "^3.0.0",
    "prop-types": "^15.6.0",
    "react": "^16.2.0",
    "react-dom": "^16.2.0",
    "semantic-ui-css": "^2.2.14",
    "semantic-ui-react": "^0.78.2"
  },
  "scripts": {
    "lint-staged": "$(yarn bin)/lint-staged"
  },
  "lint-staged": {
    "config/webpack/**/*.js": [
      "prettier --write",
      "eslint",
      "git add"
    ],
    "frontend/**/*.js": [
      "prettier --write",
      "eslint",
      "git add"
    ],
    "frontend/**/*.css": [
      "prettier --write",
      "stylelint --fix",
      "git add"
    ]
  },
  "pre-commit": [
    "lint-staged"
  ],
  "devDependencies": {
    "babel-eslint": "^8.0.1",
    "eslint": "^4.8.0",
    "eslint-config-airbnb-base": "^12.0.1",
    "eslint-config-prettier": "^2.6.0",
    "eslint-import-resolver-webpack": "^0.8.3",
    "eslint-plugin-import": "^2.7.0",
    "eslint-plugin-prettier": "^2.3.1",
    "lint-staged": "^4.2.3",
    "pre-commit": "^1.2.2",
    "prettier": "^1.7.3",
    "stylelint": "^8.1.1",
    "stylelint-config-standard": "^17.0.0",
    "webpack-dev-server": "^2.11.1"
  }
}
JSON
run 'yarn install'

# Config Files
########################################
file '.eslintrc', <<-JSON
{
  "extends": ["eslint-config-airbnb-base", "prettier"],

  "plugins": ["prettier"],

  "env": {
    "browser": true
  },

  "rules": {
    "prettier/prettier": "error"
  },

  "parser": "babel-eslint",

  "settings": {
    "import/resolver": {
      "webpack": {
        "config": {
          "resolve": {
            "modules": ["frontend", "node_modules"]
          }
        }
      }
    }
  }
}
JSON

file '.stylelintrc', <<-JSON
{
  "extends": "stylelint-config-standard"
}
JSON


# Dev environment
########################################


# Layout
########################################
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>TODO</title>
    <%= csrf_meta_tags %>
    <%#= stylesheet_pack_tag 'application', media: 'all' %> <!-- Uncomment if you import CSS in app/javascript/packs/application.js -->
  </head>
  <body>
    <%= yield %>
    <%= javascript_pack_tag 'application' %>
  </body>
</html>
HTML

# README
########################################
markdown_file_content = <<-MARKDOWN
Rails app generated with [rodloboz/rails-templates](https://github.com/rodloboz/rails-templates).
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<-RUBY
config.generators do |g|
    g.test_framework  false
    g.stylesheets     false
    g.javascripts     false
    g.helper          false
    g.channel         assets: false
  end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + pages controller
  ########################################
  rake 'db:drop db:create db:migrate'
  generate(:controller, 'pages', 'home', '--skip-routes')

  # Routes
  ########################################
  route "root to: 'pages#home'"

  # Git ignore
  ########################################
  run 'rm .gitignore'
  file '.gitignore', <<-TXT
.bundle
log/*.log
tmp/**/*
tmp/*
!log/.keep
!tmp/.keep
*.swp
.DS_Store
public/assets
public/packs
public/packs-test
node_modules
.byebug_history
TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  prepend_view_path Rails.root.join("frontend")
  before_action :authenticate_user!
end
RUBY

  # migrate + devise views
  ########################################
  rake 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<-RUBY
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]
  def home
  end
end
RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  ########################################
  run 'mv app/javascripts frontend'
  gsub_file('config/webpacker.yml', 'source_path: app/javascript', 'source_path: frontend')

  run 'rm frontend/packs/application.js'
  file 'frontend/packs/application.js', <<-JS
import "init";
JS

  run 'mkdir frontend/init'
  file 'frontend/init/index.js', <<-JS
import "./index.css";
  JS

  file 'frontend/init/index.css', <<-HTML
@import "normalize.css/normalize.css";

body {
  font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
  font-size: 16px;
  line-height: 24px;
}
  HTML

  # Figaro
  ########################################
  run 'bundle binstubs figaro'
  run 'figaro install'

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit with react-devise template"
end
