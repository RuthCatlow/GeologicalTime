#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

require('dotenv').load({path: __dirname+'/.env'});

var program = require('commander');
var path = require('path');
var winston = require('winston');
var Client = require('ftp');

winston.add(winston.transports.File, {filename: __dirname+'/ftp.log', timestamp: true});

program
  .version('0.0.1')
  .option('-f, --file [path]', 'File to upload', 'foo.txt')
  .option('-o, --output [path]', 'Change the output directory', __dirname+'/../output')
  .parse(process.argv);

function ftpSend(){
  winston.log('info', 'FTP client connecting');
  winston.log('info', program.file);

  var filename = path.basename(program.file)
  var options = {
    host: process.env.GTP_HOST,
    user: process.env.GTP_USER,
    password: process.env.GTP_PASSWORD
  };

  winston.log('info', options);
  var baseDirectory = process.env.GTP_BASE_DIR;
  var c = new Client();
  c.on('ready', function() {
    winston.log('info', 'FTP client ready');
    c.put(program.file, baseDirectory+'/videos/'+filename, function(err) {

      if(err) logError(program.file, err);
      winston.log('info', 'Successfully uploaded: '+program.file);

      // If successful then upload count.json.
      c.put(program.output+'/count.json', baseDirectory+'/count.json', function(err) {

        if(err) logError('count.json', err);
        winston.log('info', 'Successfully uploaded: count.json');

        c.end();
      });
    });
  });
	c.connect(options);
}

function logError(file, err){
  winston.log('error', 'Error uploading: '+file);
  winston.log('error', JSON.stringify(err));
  throw err;
}

ftpSend();
