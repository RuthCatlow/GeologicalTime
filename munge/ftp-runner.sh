#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

require('dotenv').load({path: __dirname+'/.env'});
var running = require('is-running')
var fs = require('fs');

// Check if lock file is present. i.e. process is active.
var locked = false
try {
  var pid = fs.readFileSync(__dirname+'/../output/ftp-pid', 'utf8');

  if(running(pid)){
    locked = true;
    winston.log('info', 'An ftp process is running');
  }
} catch (e) {
  // console.log(e);
}

if(locked === true){
  process.exit();
  return;
}

var config = {
  detached : true
};

var pid = run_cmd(__dirname+'/ftp.sh', {}, config);
fs.writeFile(__dirname+'/../output/ftp-pid', pid);

function logError(file, err){
  winston.log('error', 'Error uploading: '+file);
  winston.log('error', JSON.stringify(err));
  throw err;
}

function run_cmd(cmd, args, config, callback ) {
  var spawn = require('child_process').spawn;
  var child = spawn(cmd, args, config);
  var resp = "";

  if(config.detached === true){
    return child.pid;
  }

  child.stdout.on('data', function (buffer) { console.log(buffer) });
  child.stderr.on('data', function (buffer) { });
  child.stdout.on('end', function() {
    callback();
  });
  child.stdout.on('error', function() { console.log('err') });
  return child.pid;
}