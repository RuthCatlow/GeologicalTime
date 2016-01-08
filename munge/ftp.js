'use strict';

require('dotenv').load({path: __dirname+'/.env'});

var program = require('commander');
var path = require('path');
var winston = require('winston');
var Client = require('ftp');

function ftpSend(file){
  winston.log('info', 'FTP client connecting');
  winston.log('info', file);

  var filename = path.basename(file)
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
    c.put(file, baseDirectory+'/videos/'+filename, function(err) {
      if(err){
        winston.log('error', 'Error uploading: '+program.file);
        winston.log('error', JSON.stringify(err));
        throw err;
      }
      winston.log('info', 'Successfully uploaded: '+file);
      c.end();
    });
  });
	c.connect(options);
}

module.exports = ftpSend;
