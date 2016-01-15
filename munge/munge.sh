#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

// Examples ffmpeg command: ffmpeg -f image2 -r 5.05555555556 -i out%d.png -y -vcodec libx264 -r 24 -crf 24 test004-1000k-crf24.mp4

var fs = require('fs');
var path = require('path');
var util = require('util');

var winston = require('winston');
var program = require('commander');
var walk = require('walk');
var rmraf = require('rimraf');

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

var re = /0*([1-9][0-9]*|0)/;
var tmpDirList = fileList(program.output+'/tmp');
var writeDirList = fileList(program.output+'/write');
// If more than one image then we're playing catch up.
if(tmpDirList.length <= 1){
	// Check if next image in tmp is the next in order.
	var match = tmpDirList[0].match(re);
	if(match == null || match[1] != writeDirList.length+1){
		winston.log('error', 'Image in tmp/ is not the next image.');
	} else {
		winston.log('info', '<<<<<<<<<<<<<<< Starting image reordering >>>>>>>>>>>>>>>>>>>');
		reorderImages();
	}
} else {
	winston.log('error', 'Too many images in tmp: ', tmpDirList.length);
}

function reorderImages(){

	var args = [
		program.output
	];
	var config = {
		detached : false,
		stdio: ['pipe', 'pipe', 'pipe']
	};

	run_cmd(
		__dirname+'/reorder.sh', args, config, function(numFiles){
			writeVideo();
		}
	);
}

function fileList(dir) {
  return fs.readdirSync(dir).reduce(function(list, file) {
    var name = [dir, file].join('/');
		if(['png', 'jpg', 'jpeg'].indexOf(file.split('.').pop().toLowerCase()) === -1){
			return list;
		}
    var isDir = fs.statSync(name).isDirectory();
    return list.concat(isDir ? fileList(name) : [name]);
  }, []);
}

function writeVideo(){
	images = fileList(program.output+'/write');
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
		args.push('-cfr');
		args.push(26);
	}
	args.push(outputFile);

  var config = {
    detached : false,
    stdio: ['pipe', 'pipe', 'pipe']
  };
  winston.log('info', 'Start encoding: ffmpeg '+ args.join(' '));
  run_cmd(
    'ffmpeg', args, config, function(numFiles){
      var secs = elapsedTime();
  		winston.log('info', 'Complete in ' + secs  + 's');
      uploadVideo(outputFile, numFiles, secs);
    }
  );
}

function uploadVideo(filePath, numFiles, time){
  var args = [
    '-f', filePath,
    '-i', program.output + "/tmp/out"+pad('00000', images.length)+'.png'
  ];

  var config = {
    detached : true,
    stdio: ['ignore', 'ignore', 'ignore']
  };

  // Write file count before
  fs.writeFile(program.output + "/count.json", JSON.stringify({count:numFiles, time: time }), function(err) {
    if(err) {
      winston.log('error', err);
      return
    }
  	winston.log('info', 'Starting upload');
    run_cmd(__dirname+'/ftp.sh', args, config, function(){});
    process.exit();
  });
}

function run_cmd(cmd, args, config, callback ) {
  var spawn = require('child_process').spawn;
  var child = spawn(cmd, args, config);
  var resp = "";

  if(config.detached === true){
    return;
  }

  child.stdout.on('data', function (buffer) { console.log(buffer) });
  child.stdout.on('end', function() {
    callback(images.length);
  });
  child.stdout.on('error', function() { console.log('err') });
}

function pad(pad, str) {
  return (pad + str).slice(-pad.length);
}

function elapsedTime(){
  var elapsedSeconds = process.hrtime(startTime)[0];
  startTime = process.hrtime();
	return elapsedSeconds;
}
