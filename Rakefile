require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'
require 'open-uri'
require 'dotenv/tasks'
require 'logger'
require 'dotenv'

def create_with_sh(command, path)
  begin
    sh "#{command} > #{path}"
  rescue
    sh "rm -f #{path}"
    raise
  end
end

require 'rspec/core/rake_task'
desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  #t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
end

task :default => :spec

task :dotenv_default_dev do
  rack_env = ENV['RACK_ENV'] || 'development'
  Dotenv.load! ".env.#{rack_env}"
end

task :dotenv_default_test do
  rack_env = ENV['RACK_ENV'] || 'test'
  Dotenv.load! ".env.#{rack_env}"
end

task :env_for_sleep do
  ENV['SPEC'] = 'spec/sleep.rb'
  ENV['RACK_ENV'] = 'test' # so database is correct
end

task :spec_sleep => [:dotenv_default_test, :env_for_sleep,
                     :'db:reset_test_db', :spec]

task :start_selenium_hub_server do
  command = "java -jar spec/selenium-server-standalone-2.39.0.jar -role hub >>selenium-server.log 2>&1"
  puts command
  pid = spawn(command, out: :close) # suppress stdout
  puts 'Waiting for selenium server to start'
  while true
    begin
      open('http://localhost:4444/')
      break
    rescue Errno::ECONNREFUSED => e
      # ignore it
    rescue => e
      Process.kill 'INT', pid
      raise
    end
    print '.'
    sleep 1
  end
end

task :env_for_selenium_remote do
  ENV['REMOTE']            = 'true'
  ENV['SELENIUM_HOST']     = 'localhost'
  ENV['SELENIUM_PORT']     = '4444'
  ENV['SELENIUM_BROWSER']  = 'internet explorer'
  ENV['SELENIUM_PLATFORM'] = 'XP'
  ENV['SELENIUM_VERSION']  = ''
  ENV['BROWSER_URL']       = 'http://10.0.2.2:3000/'
  ENV['RACK_ENV'] = 'test' # so database is correct
end

task :spec_vm => [:dotenv_default_test, :env_for_selenium_remote,
                  :'db:reset_test_db', :spec]

task :env_for_selenium_sauce do
  ENV['REMOTE']            = 'true'
  ENV['SELENIUM_HOST']     = 'ondemand.saucelabs.com'
  ENV['SELENIUM_PORT']     = '4444'
  ENV['SELENIUM_BROWSER']  = 'googlechrome'
  ENV['SELENIUM_PLATFORM'] = 'linux'
  ENV['SELENIUM_VERSION']  = ''
  ENV['BROWSER_URL']       = 'http://107.170.40.128/'
  ENV['SAUCE_USERNAME']    or raise "No ENV[SAUCE_USERNAME]"
  ENV['SAUCE_ACCESS_KEY']  or raise "No ENV[SAUCE_ACCESS_KEY]"
  ENV['RACK_ENV'] = 'test' # so database is correct
end

task :spec_sauce => [:env_for_selenium_sauce, :spec]

task :karma do
  puts system('node_modules/.bin/karma start')
end

task :clean do
  sh 'rm -rf app/concat'
  sh 'rm -rf test/concat'
  sh 'rm -rf dist'
end

file 'app/concat/all.css' => %w[
  app/bower_components/todomvc-common/base.css
] do |task|
  mkdir_p 'app/concat'
  command = "cat #{task.prerequisites.join(' ')}"
  create_with_sh command, task.name
end

file 'app/concat/ie8.js' => %w[
  app/bower_components/modernizr/modernizr.js
  app/ie8-clear-local-storage.js
  app/bower_components/es5-shim/es5-shim.js
  app/bower_components/es5-shim/es5-sham.js
  app/bower_components/console-polyfill/index.js
  app/ie8-set-selection-range.js
] do |task|
  mkdir_p 'app/concat'
  command = "cat #{task.prerequisites.join(' ')}"
  create_with_sh command, task.name
end

file 'app/concat/deferred.js' do |task|
  mkdir_p 'app/concat'
  # calls to sed are to fix bug with IE8 reserved words
  command = %W[
    node_modules/.bin/browserify
      --insert-global-vars ''
      -r deferred
  | sed 's/continue/continue_/g'
  | sed 's/finally/finally_/g'
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/concat/deferred-min.js' => 'app/concat/deferred.js' do |task|
  command = %W[
    node_modules/uglifyify/node_modules/uglify-js/bin/uglifyjs
      #{task.prerequisites.join(' ')}
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/concat/vendor.js' => %w[
  app/bower_components/react/react-with-addons.js
  app/bower_components/director/build/director.js
  app/bower_components/underscore/underscore.js
  app/concat/deferred.js
] do |task|
  mkdir_p 'app/concat'
  command = "cat #{task.prerequisites.join(' ')}"
  create_with_sh command, task.name
end

file 'app/concat/browserified.js' => Dir.glob('app/*.coffee') do |task|
  mkdir_p 'app/concat'
  dash_r_paths = task.prerequisites.map { |path|
    ['-r', "./#{path}"]
  }.flatten.join(' ')
  command = %W[
    node_modules/.bin/browserify
    -t coffeeify
    --insert-global-vars ''
    -d
    -r underscore -r react
    -u xmlhttprequest -u deferred
    #{dash_r_paths}
  ].join(' ')
  create_with_sh command, task.name
end

file 'app/concat/bg.png' =>
  'app/bower_components/todomvc-common/bg.png' do |task|
  copy task.prerequisites.first, task.name
end

file 'app/concat' => %w[
  app/concat/all.css
  app/concat/ie8.js
  app/concat/vendor.js
  app/concat/browserified.js
  app/concat/bg.png
]

file 'test/concat/ie8.js' => 'app/concat/ie8.js' do |task|
  mkdir_p 'test/concat'
  copy task.prerequisites.first, task.name
end

# How to write new patch files (to fix <100% test coverage):
# - Remove line that does rm -rf app-compiled
# - Rerun task to generate app-compiled
# - cp app-compiled/CommandDoer.js app-compiled/CommandDoer-patched.js
# - diff -u app-compiled/CommandDoer.js app-compiled/CommandDoer-patched.js
#     > test/CommandDoer.patch
# - Test with patch app-compiled/CommandDoer.js test/CommandDoer.patch
# - Add patch below
file 'test/concat/browserified-coverage.js' =>
    Dir.glob(['app/*.coffee', 'test/*.coffee']) do |task|
  mkdir_p 'app/concat'
  dash_r_paths = task.prerequisites.map { |path|
    if path.start_with?('app/')
      path = path.gsub(%r[^app/], 'app-istanbul/')
      path = path.gsub(%r[\.coffee$], '.js')
      ['-r', "./#{path}"]
    end
  }.compact.flatten.join(' ')
  non_dash_r_paths = task.prerequisites.select { |path|
    path.start_with?('test/')
  }.join(' ')
  command = %W[
    rm -rf app-compiled app-istanbul
  ; cp -R app app-compiled
  ; node_modules/coffeeify/node_modules/coffee-script/bin/coffee
      -c app-compiled/*.coffee
  ; rm -rf
      app-compiled/bower_components
      app-compiled/concat
      app-compiled/shims
  ; rm app-compiled/*.coffee
  ; perl -pi -w -e 's/\.coffee/\.js/g;' app-compiled/*.js
  ; node_modules/.bin/istanbul
      instrument
      app-compiled
      --no-compact
      --embed-source
      --preserve-comments
      -o app-istanbul
  ; node_modules/.bin/browserify
    --insert-global-vars ''
    -t coffeeify
    -d
    -r underscore -r react
    -u xmlhttprequest -u deferred
    #{dash_r_paths}
    #{non_dash_r_paths}
  ].join(' ')
  create_with_sh command, task.name

  command = %Q[
    rm -rf app-compiled app-istanbul;
    perl -pi -e "s/require\\('..\\/app\\/(.*)\\.coffee'\\)/require\\('.\\/app-istanbul\\/\\1.js'\\)/g" #{task.name}
  ]
  sh command
end

file 'test/concat/vendor.js' => %w[
  test/react-with-test-utils.js
  app/bower_components/director/build/director.js
  app/bower_components/underscore/underscore.js
  app/concat/deferred.js
] do |task|
  mkdir_p 'test/concat'
  command = "cat #{task.prerequisites.join(' ')}"
  create_with_sh command, task.name
end

# need to generate app/concat/ie8.js because test/concat/ie8.js symlinks to it
file 'test/concat' => %w[
  test/concat/ie8.js
  test/concat/vendor.js
  test/concat/browserified-coverage.js
]

file 'dist/concat/all.css' => ['app/concat/all.css'] do |task|
  mkdir_p 'dist/concat'
  command = %W[
    cat
    #{task.prerequisites.join(' ')}
    | node_modules/clean-css/bin/cleancss
  ].join(' ')
  create_with_sh command, task.name
end

file 'dist/concat/ie8.js' => 'app/concat/ie8.js' do |task|
  command = %W[
    node_modules/uglifyify/node_modules/uglify-js/bin/uglifyjs
    #{task.prerequisites.join(' ')}
  ].join(' ')
  create_with_sh command, task.name
end

file 'dist/concat/vendor.js' => %w[
  app/bower_components/react/react-with-addons.min.js
  app/bower_components/director/build/director.min.js
  app/bower_components/underscore/underscore-min.js
  app/concat/deferred-min.js
] do |task|
  mkdir_p 'dist/concat'
  command = "cat #{task.prerequisites.join(' app/semicolon.js ')}"
  create_with_sh command, task.name
end

file 'dist/concat/browserified.js' => Dir.glob('app/*.coffee') do |task|
  mkdir_p 'dist/concat'
  dash_r_paths = task.prerequisites.map { |path|
    ['-r', "./#{path}"]
  }.flatten.join(' ')
  command = %W[
    node_modules/.bin/browserify
      -t coffeeify
      -t uglifyify
      --insert-global-vars ''
      -d
      -r underscore -r react
      -u xmlhttprequest -u deferred
      #{dash_r_paths}
  | node
      node_modules/exorcist/bin/exorcist.js
      dist/concat/browserified.js.map
  ].join(' ')
  create_with_sh command, task.name
end

task :dist => %w[
  app/index.html
  dist/concat/all.css
  dist/concat/ie8.js
  dist/concat/vendor.js
  dist/concat/browserified.js
  app/concat/bg.png
] do
  mkdir_p 'dist'

  cp 'app/index.html', 'dist/index.html'
  %w[all.css ie8.js vendor.js browserified.js].each do |filename|
    new_filename = File.basename(
      `node_modules/.bin/busta --file dist/concat/#{filename}`).strip
    command = %W[
      cat dist/index.html | sed "s/#{filename}/#{new_filename}/"
      > dist/index.html.tmp
      ; mv dist/index.html.tmp dist/index.html
    ].join(' ')
    sh command
  end

  mkdir_p 'dist/concat'
  cp 'app/concat/bg.png',          'dist/concat/bg.png'
end

task :unit_test_cov do
  command = %W[
    rm -rf app-compiled test-compiled
  ; cp -R app app-compiled
  ; coffee -c app-compiled
  ; cp -R test test-compiled
  ; coffee -c test-compiled
  ; perl -pi -e "s/require\\('.\\/(.*)\\.coffee'\\)/require\\('.\\/\\1.js'\\)/g" app-compiled/*.js
  ; perl -pi -e "s/require\\('..\\/app\\/(.*)\\.coffee'\\)/require\\('..\\/app-compiled\\/\\1.js'\\)/g" test-compiled/*.js
  ; perl -pi -e "s/require\\('..\\/test\\/(.*)\\.coffee'\\)/require\\('..\\/test-compiled\\/\\1.js'\\)/g" test-compiled/*.js
  ; node_modules/.bin/istanbul cover
      node_modules/.bin/_mocha --
        -u exports
        -R spec
        -r app-compiled/TodoItem.js
        -r app-compiled/TodoWrapper.js
        -r app-compiled/TodoApp.js
        -r app-compiled/TodoFooter.js
        -r app-compiled/Ajax.js
        -r app-compiled/SimulateCommand.js
        -r app-compiled/SyncCommand.js
        -r app-compiled/SyncedState.js
        test-compiled/TodoItemTest.js
        test-compiled/TodoFooterTest.js
        test-compiled/TodoItemTest.js
        test-compiled/SyncCommandTest.js
        test-compiled/SyncedStateTest.js
  ; node_modules/.bin/istanbul report
  ; rm -rf app-compiled test-compiled
  ; open coverage/lcov-report/app-compiled/index.html
  ].join(' ') # Leave out TodoAppTest.js since it requires browser
  sh command
end

task :sauce_test, [:web_server_ip] => 'test/concat' do |t, args|
  raise "Call with web_server_ip argument" if args[:web_server_ip].nil?

  files_to_sync = %w[
    test/index.html
    test/bower_components/jasmine/lib/jasmine-core/jasmine.js
    test/bower_components/jasmine/lib/jasmine-core/jasmine.css
    test/bower_components/jasmine/lib/jasmine-core/jasmine-html.js
    test/bower_components/jasmine/lib/jasmine-core/boot.js
    test/concat/ie8.js
    test/concat/vendor.js
    test/concat/browserified-coverage.js
    test/jsreporter_jasmine2.js
  ].join(' ')
  sh "rsync -vzr -e ssh -R --delete #{files_to_sync} deployer@#{args[:web_server_ip]}:/home/deployer/todomvc-test"
  sh "ruby test/sauce_start.rb http://#{args[:web_server_ip]}:3000/test/"
end

namespace :db do
  task :sequel => :dotenv_default_dev do
    require 'sequel'
    Sequel.extension :migration
    $db = Sequel.connect(ENV.fetch('DATABASE_URL'))
    $db.logger = Logger.new($stdout)
  end

  task :sequel_test => [:dotenv_default_test, :sequel]

  desc 'Run DB migrations'
  task :migrate, [:version] => :sequel do |t, args|
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run $db, 'db/migrations',
        target: args[:version].to_i
    else
      puts "Migrating to latest"
      Sequel::Migrator.run $db, 'db/migrations'
    end
  end

  desc 'Rollback migration'
  task :rollback => :sequel do
    version = $db[:schema_info].first[:version]
    Sequel::Migrator.apply $db, 'db/migrations', version - 1
  end

  desc 'Dump the database schema'
  task :dump => :sequel do
    sh "sequel -d #{$db.url} > db/schema.rb"
    sh "pg_dump --schema-only #{$db.url} > db/schema.sql"
  end

  task :reset_test_db => :sequel_test do
    require 'database_cleaner'
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end
end
