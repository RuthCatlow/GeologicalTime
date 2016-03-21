#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

require('dotenv').load({path: __dirname+'/.env'});

var fs = require('fs');
var program = require('commander');
var path = require('path');
var winston = require('winston');
var ssh2 = require("ssh2");
var http = require("http");

var fileExists = require('file-exists');

var mailOptions = {
	to: 'gareth.foote@gmail.com',
	from: 'gtp@garethfoote.co.uk',
	host: 'smtp.webfaction.com',
	port: 25,
	username: 'foote_gtp',
	password: process.env.GTP_PASSWORD
};

var baseDirectory = process.env.GTP_BASE_DIR;
var c = new ssh2();
var sftp;

require('winston-mail').Mail;
winston.add(winston.transports.Mail, mailOptions);
winston.add(winston.transports.File, {filename: __dirname+'/ftp.log', timestamp: true});

program
  .version('0.0.1')
  .option('-f, --video [path]', 'File to upload', 'foo.txt')
  .option('-i, --image [path]', 'Image to upload')
  .option('-o, --output [path]', 'Change the output directory', __dirname+'/../output')
  .parse(process.argv);

function ftpSend(fileNum){
  winston.log('info', '<<<<<<<<<<<< SFTP client connecting >>>>>>>>>>>>');

  var image = program.output + "/tmp/out"+pad('00000', fileNum)+'.png'
  var video = program.output + "/videos/video-"+pad('00000', fileNum)+'.mp4'

/*
  fs.unlinkSync(program.output + "/count.json", function(){
    winston.info('info', 'Count json deleted whilst uploading');
  });
*/
  var options = {
    host: process.env.GTP_HOST,
    username: process.env.GTP_USER,
    password: process.env.GTP_PASSWORD
  };
  var files = [
    { src: video, dest: baseDirectory+'videos/'+path.basename(video) },
    { src: image, dest: baseDirectory+'images/'+path.basename(image) },
  ];
  var count = 0;

  c.on('ready', function () {
    winston.log('info', 'SFTP client ready');

    c.sftp(function (err, _sftp) {
      if(err) {
        winston.log('error', err);
        throw err;
      }
      sftp = _sftp;

      files.forEach(function(file){
        sftp.fastPut(file.src, file.dest, {}, function (err) {
          count++;
          if(err) {
            logError(file.src, err);
          }
          winston.log('info', 'Uploaded: ' + file.src);
          if(count === files.length){
            finish(image, fileNum);
          }
        });
      });

    });
  });
   
  c.connect(options);
}

function finish(image, fileNum){

  // Delete image
  fs.unlinkSync(image, function(){
    winston.info('Image deleted');
  });

  // Create count.json
  fs.writeFileSync(program.output + "/count.json", JSON.stringify({count:fileNum}));

  // Upload count.json.
  sftp.fastPut(program.output+'/count.json', baseDirectory+'count.json', {}, function (err) {
    if(err) {
      logError(file.src, err);
    }
    winston.log('info', 'Uploaded: count.json');
    c.end();
  });

}

/* Do not continue if count is missing.
if(!fileExists(program.output + "/count.json")){
  winston.log('info', 'count.json missing so is currently uploading.');
  return;
}*/

// Check if anything to upload.
var re = /0*([1-9][0-9]*|0)/;
var videoDirList = fileList(program.output+'/videos').reverse();
var tmpDirList = fileList(program.output+'/tmp');
var matchTmp = tmpDirList[0].match(re);
// The second to most recent because the first could be encoding still.
var matchVid = videoDirList[1].match(re);
if(matchTmp[1] <= matchVid[1]){
  winston.log('info', 'Send:'+ matchTmp[1]);
  ftpSend(matchTmp[1]);
} else {
  winston.log('info', 'Nothing to send');
}
console.log("Ready to upload vid: " +matchVid[1]);
console.log("Ready to upload tmp: " +matchTmp[1]);

function fileList(dir) {
  return fs.readdirSync(dir).reduce(function(list, file) {
    var name = [dir, file].join('/');
		if(['png', 'jpg', 'jpeg', 'mp4'].indexOf(file.split('.').pop().toLowerCase()) === -1){
			return list;
		}
    var isDir = fs.statSync(name).isDirectory();
    return list.concat(isDir ? fileList(name) : [name]);
  }, []);
}

function pad(pad, str) {
  return (pad + str).slice(-pad.length);
}

function logError(file, err){
  winston.log('error', 'Error uploading: '+file);
  winston.log('error', JSON.stringify(err));
  throw err;
}
