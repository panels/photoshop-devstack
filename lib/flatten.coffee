fs = require 'fs'
path = require 'path'
glob = require 'glob'
temp = require 'temp'
execSync = require 'exec-sync'
flatten = require 'flatten-deps'

run = (cmd) ->
  console.log "> #{cmd}"
  execSync cmd

repoDir = process.cwd()
packagePath = path.join repoDir, 'package.json'

meta = require packagePath

# looking for npm pack'ed archive
archive = meta.name + '-' + meta.version + '.tgz'

files = glob.sync archive,
  cwd: repoDir

if files[0]?
  file = files[0]

  temp.track()
  tempDir = temp.mkdirSync 'untar0'
  console.log 'Using tmp dir', tempDir

  console.log 'Extracting file', file
  res = run 'tar -xf ' + file + ' -C ' + tempDir
  console.log res

  console.log 'Cleaning dependencies ...'
  packageDir = path.join tempDir, 'package'
  flatten packageDir

  # fs.renameSync packageDir, './package-' + meta.version

  console.log 'Creating tar ...'
  tarFile = meta.name + '-' + meta.version + '.build.tgz'
  res = run 'tar -czf ' + tarFile + ' -C ' + tempDir + ' package'
  console.log res

else
  console.log 'No archives found. Run `npm pack` first.'
