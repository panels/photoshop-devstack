path = require 'path'
spawn = require('child_process').spawn

generator = path.resolve __dirname, '..', 'node_modules', 'generator-core', 'app'

spawn 'sh', ['-c', "node #{generator} -f ."], stdio: 'inherit'
