#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

require('dotenv').load({path: __dirname+'/.env'});

var fs = require('fs');
var program = require('commander');
var path = require('path');
var winston = require('winston');
var Client = require('ftp');

winston.add(winston.transports.File, {filename: __dirname+'/ftp.log', timestamp: true});

program
  .version('0.0.1')
  .option('-f, --file [path]', 'File to upload', 'foo.txt')
  .option('-i, --image [path]', 'Image to upload')
  .option('-o, --output [path]', 'Change the output directory', __dirname+'/../output')
  .parse(process.argv);

function ftpSend(){
  winston.log('info', 'FTP client connecting');

  var options = {
    host: process.env.GTP_HOST,
    user: process.env.GTP_USER,
    password: process.env.GTP_PASSWORD
  };

  var baseDirectory = process.env.GTP_BASE_DIR;
  var c = new Client();
  c.on('ready', function() {
    c.put(program.file, baseDirectory+'/videos/'+path.basename(program.file), function(err) {

      if(err) logError(program.file, err);
      winston.log('info', 'Successfully uploaded: '+program.file);

      // If successful then upload image
      c.put(program.image, baseDirectory+'/images/'+path.basename(program.image), function(err) {

        if(err) logError(program.image, err);
        winston.log('info', 'Successfully uploaded: '+ program.image);

          fs.unlinkSync(program.image, function(){
            winston.info('Image deleted');
          });

          // If successful then upload count.json.
          c.put(program.output+'/count.json', baseDirectory+'/count.json', function(err) {
            if(err) logError('count.json', err);
            winston.log('info', 'Successfully uploaded: count.json');
            c.end();
          });

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
