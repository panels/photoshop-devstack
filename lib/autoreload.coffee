path = require 'path'
esteWatch = require 'este-watch'
execSync = require 'exec-sync'
color = require 'bash-color'
fork = require('child_process').fork

coffee = path.resolve __dirname, '..', 'node_modules', '.bin', 'coffee'
buildBackend = path.resolve __dirname, 'build-backend.coffee'
generator = path.resolve __dirname, '..', 'node_modules', 'generator-core', 'app'
node = process.execPath

log = (msg) ->
  console.log ''
  console.log "#{color.green('[panel-photoshop-devstack]')} #{msg}"
  console.log ''

buildAndRun = ->
  execSync "#{coffee} #{buildBackend} --dev"
  server = fork generator, ['-f', '.'], execArgv: ['--debug']
  server.on 'close', (code) ->
    if code is 0
      log 'Restarting Generator in 3s'
      setTimeout () ->
          server = null
          server = buildAndRun()
      , 3000


log 'Starting server'
server = buildAndRun()

watcher = esteWatch ['src'], (e) ->
  log 'Change in filesystem detected, restarting'

  if server
    server.kill 'SIGINT'
    server = null

  server = buildAndRun()

watcher.start()

process.once 'SIGTERM', ->
  server.kill?('SIGINT')
  process.exit(0)
