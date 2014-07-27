path = require 'path'
execSync = require 'exec-sync'

dotBin = path.resolve __dirname, '..', 'node_modules', '.bin'
coffee = path.join dotBin, 'coffee'
uglify = path.join dotBin, 'recursive-uglifyjs'

execSync "#{coffee} -o lib src"
execSync "#{uglify} lib"
