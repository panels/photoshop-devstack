gulp = require 'gulp'
coffee = require 'gulp-coffee'
uglify = require 'gulp-uglify'
addSrc = require 'gulp-add-src'

gulp.src 'src/**/*.coffee'
  .pipe coffee()
  .pipe addSrc 'src/**/*.js'
  .pipe uglify()
  .pipe gulp.dest 'lib'
