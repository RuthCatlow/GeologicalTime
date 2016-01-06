#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

require('dotenv').load();

var program = require('commander');
var path = require('path');
var winston = require('winston');

winston.add(winston.transports.File, {filename: 'ftp.log', timestamp: true});

var Client = require('ftp');
program
  .version('0.0.1')
  .option('-f, --file [path]', 'File to upload', 'foo.txt')
  .parse(process.argv);

function ftpSend(){
  winston.log('info', 'FTP client connecting');

  var filename = path.basename(program.file)
  var options = {
    host: process.env.GTP_HOST,
    user: process.env.GTP_USER,
    password: process.env.GTP_PASSWORD
  };

  var baseDirectory = process.env.GTP_BASE_DIR;
  var c = new Client();
  c.on('ready', function() {
    winston.log('info', 'FTP client ready');
    c.put(program.file, baseDirectory+'latest.mp4', function(err) {
      if(err){
        winston.log('error', 'Error uploading: '+program.file);
        winston.log('error', JSON.stringify(err));
        throw err;
      }
      winston.log('info', 'Successfully uploaded: '+program.file);
      c.end();
    });
  });
	c.connect(options);
}

ftpSend();
