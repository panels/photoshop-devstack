path = require 'path'
esteWatch = require 'este-watch'
color = require 'bash-color'
fork = require('child_process').fork
exec = require('child_process').exec
psTree = require 'ps-tree'

coffee = path.resolve __dirname, '..', 'node_modules', '.bin', 'coffee'
buildBackend = path.resolve __dirname, 'build-backend.coffee'
generator = path.resolve __dirname, '..', 'node_modules', 'generator-core', 'app'
node = process.execPath

log = (msg) ->
  console.log ''
  console.log "#{color.green('[panel-photoshop-devstack]')} #{msg}"
  console.log ''

lock = false

buildAndRun = (cb) ->
  return cb() if lock
  lock = true

  exec "#{coffee} #{buildBackend} --dev", (err) ->
    return console.error err if err
    child = fork generator, ['-f', '.']#, execArgv: ['--debug']
    child.on 'close', (code, signal) ->
      if code is 0
        log 'Restarting Generator in 3s'
        setTimeout () ->
          child = null
          buildAndRun (s) ->
            cb s
        , 3000
      else
        log "Generator exited. Code: #{code}, signal: #{signal}"
    cb child
    lock = false

watcher = null

log 'Starting server'

buildAndRun (server) ->
  watcher = esteWatch ['src'], (e) ->
    log 'Change in filesystem detected, restarting'

    if server
      pid = server.pid
      psTree pid, (err, children) ->
        children.unshift PID: pid

        children.forEach (child) ->
          exec "kill -9 #{child.PID}"

    server = null
    buildAndRun (s) ->
      server = s

  watcher.start()

process.once 'SIGTERM', ->
  server?.kill?('SIGINT')
  process.exit(0)
