fs = require 'fs'
path = require 'path'
exec = (require 'child_process').exec

GIT_CLONE_URL = 'ssh://gitlab@gitlab.abdoc.net:12012/madebysource/%repo%.git'

repoDir = process.cwd()
packagePath = path.join repoDir, 'package.json'

metadata = require packagePath

# node_modules linked path
panelPath = metadata.panel?.static

if not panelPath
  console.log '[get-panel] No \'panel.static\' key in package.json'
  return

panelName = path.basename panelPath

# real target path
panelResolvedPath = path.join repoDir, '..', panelName

link = ->
  if fs.existsSync panelResolvedPath
    console.log '[get-panel] Linking `../' + panelName + '`'
    exec 'npm link "' + panelResolvedPath + '"',
      (err, stdout, stderr) ->
        console.log stdout

checkInstalled = ->
  if fs.existsSync panelPath
    console.log '[get-panel] \'' + panelName + '\' installed'

    if fs.existsSync panelResolvedPath
      panelPackagePath = path.join panelResolvedPath, 'package.json'
      panelMeta = require panelPackagePath
      console.log '[get-panel] version ' + panelMeta.version
      return true
  false

if not checkInstalled()
  console.log '[get-panel] \'' + panelName + '\' link not found'

  if not fs.existsSync panelResolvedPath
    url = GIT_CLONE_URL.replace '%repo%', panelName

    console.log '[get-panel] Panel `../' + panelName + '` not found'
    console.log '[get-panel] Auto-clonning from `' + url + '`'

    exec 'git clone "' + url + '" "' + panelResolvedPath + '"',
      (err, stdout, stderr) ->
        console.log stdout
        link() unless err
  else
    link()
