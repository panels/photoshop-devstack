fs = require 'fs'
path = require 'path'
exec = (require 'child_process').exec

GIT_CLONE_URL = 'ssh://gitlab@gitlab.abdoc.net:12012/madebysource/%repo%.git'

repoDir = process.cwd()
packagePath = path.join repoDir, 'package.json'

metadata = require packagePath

# node_modules linked path
panelPath = metadata.panel?.static

log = (args) ->
  args = Array.prototype.slice.call arguments
  args.unshift '[get-panel]'
  console.log.apply console, args

if not panelPath
  log 'No \'panel.static\' key in package.json'
  return

panelName = path.basename panelPath

# real target path
panelResolvedPath = path.join repoDir, '..', panelName

link = ->
  if fs.existsSync panelResolvedPath
    log 'Linking `../' + panelName + '`'
    exec 'npm link "' + panelResolvedPath + '"',
      (err, stdout, stderr) ->
        log stdout

checkInstalled = ->
  if fs.existsSync panelPath
    log '\'' + panelName + '\' installed'

    stat = fs.lstatSync panelPath
    if stat.isSymbolicLink()
      log 'Local symlink: ', fs.readlinkSync panelPath
    else
      log 'From npm registry'

    if fs.existsSync panelResolvedPath
      panelPackagePath = path.join panelResolvedPath, 'package.json'
      panelMeta = require panelPackagePath
      log 'version ' + panelMeta.version
      return true
  false

if not checkInstalled()
  log '\'' + panelName + '\' link not found'

  if not fs.existsSync panelResolvedPath
    url = GIT_CLONE_URL.replace '%repo%', panelName

    log 'Panel `../' + panelName + '` not found'
    log 'Auto-clonning from `' + url + '`'

    exec 'git clone "' + url + '" "' + panelResolvedPath + '"',
      (err, stdout, stderr) ->
        console.log stdout
        link() unless err
  else
    link()
