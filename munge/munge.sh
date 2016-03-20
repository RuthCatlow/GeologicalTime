#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

// Examples ffmpeg command: ffmpeg -f image2 -r 5.05555555556 -i out%d.png -y -vcodec libx264 -r 24 -crf 24 test004-1000k-crf24.mp4
//
require('dotenv').load({path: __dirname+'/.env'});

var fs = require('fs');
var path = require('path');
var util = require('util');

var winston = require('winston');
var program = require('commander');
var walk = require('walk');
var rmraf = require('rimraf');

var ffmpeg = process.env.GTP_FFMPEG || '/usr/local/bin/ffmpeg';
var running = require('is-running')
var fileExists = require('file-exists');

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
winston.add(winston.transports.File, {filename: __dirname+'/munge.log', timestamp: true});

program
  .version('0.0.1')
  .option('-i, --input [path]', 'Specify an input directory')
  .option('-o, --output [path]', 'Change the output directory', __dirname+'/../output')
  .option('-d, --duration <seconds>', 'Duration of output video in seconds', 180)
  .parse(process.argv);

var inputDirectory = program.input || program.output + '/images/';
var startTime = process.hrtime();
var images = [];

var mkdirSync = function (path) {
  try {
    fs.mkdirSync(path);
  } catch(e) {
    if ( e.code != 'EEXIST' ) throw e;
  }
}

mkdirSync(program.output+'/write');

// Check if lock file is present. i.e. process is active.
var locked = false
var pid = 0;
try {
	var ffmpegPid = fs.readFileSync(program.output+'/ffmpeg-pid', 'utf8');
	var reorderPid = fs.readFileSync(program.output+'/reorder-pid', 'utf8');

	if(running(ffmpegPid) || running(reorderPid)){
  	locked = true;
  	winston.log('info', 'A process is running');
	}
} catch (e) {
	// console.log(e);
}

if(locked == false){

	var videoDirList = fileList(program.output+'/videos').reverse();
  var writeDirList = fileList(program.output+'/write');
	var nextFileNumber = writeDirList.length+1;
  var nextTmpFile = program.output+'/tmp/out'+pad('00000', nextFileNumber)+'.png';
  var nextVideoFile = program.output+'/videos/video-'+pad('00000', nextFileNumber)+'.mp4';

	if(fileExists(nextTmpFile) && !fileExists(nextVideoFile)){
  	winston.log('info', '<<<<<<<<<<<<<<< START >>>>>>>>>>>>>>>>>>>');
		reorderImages();
	} else {
		console.log('Tmp file exists:', fileExists(nextTmpFile), "Video file doesn't exist:", !fileExists(nextVideoFile));
	}
}

function reorderImages(){

	var args = [
		program.output
	];
	var config = {
		detached : false,
		stdio: ['pipe', 'pipe', 'pipe']
	};

	var pid = run_cmd(
		__dirname+'/reorder.sh', args, config, function(numFiles){
			images = fileList(program.output+'/write');
			writeVideo();
		}
	);
	fs.writeFile(program.output+'/reorder-pid', pid);
}

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

function writeVideo(){
	winston.log('info', 'Reordered '+ images.length + ' images' );

	var minOutFrameRate = 12;
  var inputFrameRate = 1/(program.duration/images.length);
  var outputFile = program.output+'/videos/video-'+pad('00000', images.length)+'.mp4';
	// http://stackoverflow.com/a/24697998/970059

	var args = [
    '-f', 'image2',
    '-r', inputFrameRate,
    '-i', program.output+'/write/out%5d.png',
    '-y',
    '-vcodec', 'libx264',
	];

  var argsAdvanced = [
		// Won't play in Android browser without this.
		'-pix_fmt', 'yuv420p',
		// Solves 'height not divisible by 2' error. http://stackoverflow.com/a/29582287/970059
		'-vf', 'scale=720:-2',
    '-movflags', 'faststart',
  ];

	if(images.length > 2){
		args = args.concat(argsAdvanced);
	}

	// Ensure min out frame rate of {minOutFrameRate}
	if(images.length < program.duration*minOutFrameRate){
		args.push('-r');
		args.push(24);
	} else {
		args.push('-crf');
		args.push(26);
	}
	args.push(outputFile);

  var config = {
    detached : false,
    stdio: ['pipe', 'pipe', 'pipe']
  };
  winston.log('info', 'Start encoding: ffmpeg '+ args.join(' '));
  var pid = run_cmd(
    ffmpeg, args, config, function(numFiles){
      winston.log('info', 'Complete');
      var secs = elapsedTime();
  		winston.log('info', 'Complete in ' + secs  + 's');
    }
  );
	fs.writeFile(program.output+'/ffmpeg-pid', pid);
	// winston.log('info', "Process id: " + pid);
}

function run_cmd(cmd, args, config, callback ) {
  var spawn = require('child_process').spawn;
  var child = spawn(cmd, args, config);
  var resp = "";

  // winston.log('info', config);

  if(config.detached === true){
    return child.pid;
  }

  child.stdout.on('data', function (buffer) { console.log(buffer) });
  child.stdout.on('end', function() {
    callback();
  });
  child.stdout.on('error', function() { console.log('err') });
	return child.pid;
}

function pad(pad, str) {
  return (pad + str).slice(-pad.length);
}

function elapsedTime(){
  var elapsedSeconds = process.hrtime(startTime)[0];
  startTime = process.hrtime();
	return elapsedSeconds;
}
