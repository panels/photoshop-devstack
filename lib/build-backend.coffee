path = require 'path'
exec = require('child_process').exec
gulp = require 'gulp'

dotBin = path.resolve __dirname, '..', 'node_modules', '.bin'
coffee = path.join dotBin, 'coffee'
uglify = path.join dotBin, 'recursive-uglifyjs'

errExit = (err) ->
  console.error err
  process.exit 1

exec "#{coffee} -o lib src", (err) ->
  errExit err if err

  gulp.src 'src/**/*.js'
    .pipe gulp.dest 'lib'
    .on 'end', () ->
      if '--dev' not in process.argv
        exec "#{uglify} lib", (err) ->
          errExit err if err
