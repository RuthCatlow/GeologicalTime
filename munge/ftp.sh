#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

require('dotenv').load({path: __dirname+'/.env'});

var fs = require('fs');
var program = require('commander');
var path = require('path');
var winston = require('winston');
var ssh2 = require("ssh2");

var mailOptions = {
	to: 'gareth.foote@gmail.com',
	from: 'gtp@garethfoote.co.uk',
	host: 'smtp.webfaction.com',
	port: 25,
	username: 'foote_gtp',
	password: process.env.GTP_PASSWORD
};

require('winston-mail').Mail;
winston.add(winston.transports.Mail, mailOptions);
winston.add(winston.transports.File, {filename: __dirname+'/ftp.log', timestamp: true});

program
  .version('0.0.1')
  .option('-f, --video [path]', 'File to upload', 'foo.txt')
  .option('-i, --image [path]', 'Image to upload')
  .option('-o, --output [path]', 'Change the output directory', __dirname+'/../output')
  .parse(process.argv);

function ftpSend(){
  winston.log('info', '<<<<<<<<<<<< SFTP client connecting >>>>>>>>>>>>');

  var options = {
    host: process.env.GTP_HOST,
    username: process.env.GTP_USER,
    password: process.env.GTP_PASSWORD
  };
  var baseDirectory = process.env.GTP_BASE_DIR;
  var files = [
    { src: program.video, dest: baseDirectory+'videos/'+path.basename(program.video) },
    { src: program.image, dest: baseDirectory+'images/'+path.basename(program.image) },
    { src: program.output+'/count.json', dest: baseDirectory+'count.json' }
  ];
  var count = 0;

  var c = new ssh2();
  c.on('ready', function () {
    winston.log('info', 'SFTP client ready');

    c.sftp(function (err, sftp) {
      if(err) {
        winston.log('error', err);
        throw err;
      }

      files.forEach(function(file){
        sftp.fastPut(file.src, file.dest, {}, function (err) {
          count++;
          if(err) {
            logError(file.src, err);
          }
          winston.log('info', 'Uploaded: ' + file.src);
          if(count === files.length){
            fs.unlinkSync(program.image, function(){
              winston.info('Image deleted');
            });
            c.end();
          }
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
