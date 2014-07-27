path = require 'path'
execSync = require 'exec-sync'

dotBin = path.resolve __dirname, '..', 'node_modules', '.bin'
uglify = path.join dotBin, 'recursive-uglifyjs'
coffee = execSync('npm bin coffee') + '/coffee'

execSync "#{coffee} -o lib src"
execSync "#{uglify} lib"
