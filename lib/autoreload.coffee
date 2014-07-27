path = require 'path'
esteWatch = require 'este-watch'
execSync = require 'exec-sync'
color = require 'bash-color'
spawn = require('child_process').spawn

coffee = execSync('npm bin coffee') + '/coffee'
buildBackend = path.resolve __dirname, 'build-backend.coffee'
generator = path.resolve __dirname, '..', 'node_modules', 'generator-core', 'app'

log = (msg) ->
  console.log ''
  console.log "#{color.green('[panel-photoshop-devstack]')} #{msg}"
  console.log ''

buildAndRun = ->
  execSync "#{coffee} #{buildBackend}"
  spawn 'sh', ['-c', "node #{generator} -f ."], stdio: 'inherit'

log 'Starting server'
server = buildAndRun()

watcher = esteWatch ['src'], (e) ->
  log 'Change in filesystem detected, restarting'

  if server
    server.kill 'SIGINT'
    server = null

  server = buildAndRun()

watcher.start()
