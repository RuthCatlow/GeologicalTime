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

function ftpSend(count){
  winston.log('info', '<<<<<<<<<<<< SFTP client connecting >>>>>>>>>>>>');

  var image = program.output + "/tmp/out"+pad('00000', count)+'.png'
  var video = program.output + "/videos/video-"+pad('00000', count)+'.mp4'
  console.log(image);
  console.log(video);

  var options = {
    host: process.env.GTP_HOST,
    username: process.env.GTP_USER,
    password: process.env.GTP_PASSWORD
  };
  var baseDirectory = process.env.GTP_BASE_DIR;
  var files = [
    { src: video, dest: baseDirectory+'videos/'+path.basename(video) },
    { src: image, dest: baseDirectory+'images/'+path.basename(image) },
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
            fs.unlinkSync(image, function(){
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

var url = 'http://gtp.ruthcatlow.net/test/count.json?_cb='+(new Date()).getTime();

http.get(url, function(res){
  var body = '';

  res.on('data', function(chunk){
    body += chunk;
  });

  res.on('end', function(){
    var response = JSON.parse(body);
    console.log("Got a response: ", response.count);

    var re = /0*([1-9][0-9]*|0)/;
    var videoDirList = fileList(program.output+'/videos').reverse();
    // Not the most recent because it could still be encoding.
    var match = videoDirList[1].match(re);
    if(match[1] > response.count){
      // console.log('upload');
      // console.log(match[1]);
      ftpSend(match[1]);
    } else {
      console.log('do not upload');
    }

  });
}).on('error', function(e){
  console.log("Got an error: ", e);
});


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
