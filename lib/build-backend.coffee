path = require 'path'
execSync = require 'exec-sync'
gulp = require 'gulp'

dotBin = path.resolve __dirname, '..', 'node_modules', '.bin'
coffee = path.join dotBin, 'coffee'
uglify = path.join dotBin, 'recursive-uglifyjs'

execSync "#{coffee} -o lib src"
gulp.src 'src/**/*.js'
  .pipe gulp.dest 'lib'
  .on 'end', () ->
    execSync "#{uglify} lib"
