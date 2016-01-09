#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

// Examples ffmpeg command: ffmpeg -f image2 -r 5.05555555556 -i out%d.png -y -vcodec libx264 -r 24 -crf 24 test004-1000k-crf24.mp4

var fs = require('fs');
var util = require('util');

var winston = require('winston');
var program = require('commander');
var walk = require('walk');
var rmraf = require('rimraf');
/// var ftp = require('./ftp');

winston.add(winston.transports.File, {filename: __dirname+'/munge.log', timestamp: true});

program
  .version('0.0.1')
  .option('-o, --output [path]', 'Change the output directory', __dirname+'/../output')
  .parse(process.argv);

var images = [];
var walker = walk.walk(program.output + '/images/', {
  followLinks: false,
  filters: ["Temp", "_Temp", ".git", ".gitkeep"]
});
var startTime = process.hrtime();

var mkdirSync = function (path) {
  try {
    fs.mkdirSync(path);
  } catch(e) {
    if ( e.code != 'EEXIST' ) throw e;
  }
}

// Make empty tmp directory
rmraf.sync('./tmp');
mkdirSync('./tmp');

walker.on("files", function (root, stats, next) {
  var nextImages = stats.map(function(file){
    return root + '/' + file.name;
  })
  // Filter out anything but jpgs
  nextImages = nextImages.filter(function(file){
    return ['png', 'jpg', 'jpeg'].indexOf(file.split('.').pop().toLowerCase()) > -1;
  });
  winston.log('debug', 'Amount of images: ' + nextImages.length)

  images = images.concat(nextImages.reverse());
  next();
});

walker.on("end", function () {
  runGenerator(copyImagesGenerator).then(function(){
    winston.log('info', 'Images copied')
    writeVideo()
  })
});

function copyImagesToTmp(files, startIndex){
  var outFilenameTpl = './tmp/out%d.png'
  return function(callback){
    files.forEach(function(file, i){
      var fileIndex = i+startIndex;
      var outFilename = util.format(outFilenameTpl, fileIndex)
      var stream = fs.createReadStream(file).pipe(fs.createWriteStream(outFilename));
      stream.on('finish', function(){
        stream.destroy();
        if(i == files.length-1){
          callback(null, startIndex)
        }
      })
    })
  }
}

function* copyImagesGenerator(){
  var sliceLength = 1000
  var slices = Math.ceil(images.length/sliceLength)
  var slice = []
  var i = 0

  images = images.reverse()

  winston.log('info', 'Start copying images ('+images.length+')');
  while(i < slices){
    winston.log('debug', 'Image batch '+ (i+1) + ' start');
    var begin = i*sliceLength
    var end = (i+1)*sliceLength;
    slice = (i < slices-1) ? images.slice(begin, end) : images.slice(begin)
    yield copyImagesToTmp(slice, begin)
    i++
    winston.log('debug', 'Image batch ' + (i+1) + ' complete')
  }
}

function runGenerator(fn) {
  return new Promise(function(resolve, reject){
    var next = function (err, arg) {
      if(err){
        winston.log('error', 'Error copying images')
        winston.log('error', err)
        return it.throw(err);
      }

      var result = it.next(arg);
      if(result.done){
        resolve();
      }

      if (typeof result.value == 'function') {
        result.value(next);
      }
    }
    var it = fn();
    next();
  })
}

function writeVideo(){
  var outputFrameRate = images.length/180
  var inputFrameRate = 1/(180/images.length)
  var outputFile = program.output+'/videos/video-'+pad('00000', images.length)+'.mp4';
  // Debug.
  // uploadVideo(outputFile, images.length); return;
  var args = [
    '-f', 'image2',
    '-r', inputFrameRate,
    '-i', './tmp/out%d.png',
    '-y',
    '-vcodec', 'libx264',
		'-pix_fmt', 'yuv420p',
    '-r', '24',
    '-crf', '26',
    '-movflags', 'faststart',
    outputFile
  ];
  var config = {
    detached : false,
    stdio: ['pipe', 'pipe', 'pipe']
  };
  winston.log('info', 'Start compressing video');
  winston.log('debug', 'command: ffmpeg '+ args.join(' '));
  run_cmd(
    'ffmpeg', args, config, function(numFiles){
      // rmraf.sync('./tmp');
      elapsedTime('Video encoding complete: '+outputFile);
      uploadVideo(outputFile, numFiles);
    }
  );
}

function uploadVideo(filePath, numFiles){
  winston.log('info', 'Starting FTP upload '+filePath);
  var args = [
    '-f', filePath
  ];
  var config = {
    detached : true,
    stdio: ['ignore', 'ignore', 'ignore']
  };
  // ftp(filePath);
  // Write file count before
  fs.writeFile(program.output + "/count.json", JSON.stringify({count:numFiles}), function(err) {
    if(err) {
      winston.log('error', err);
      return
    }
    winston.log("info", "Count file was saved");
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
    callback(images.length)
  });
  child.stdout.on('error', function() { console.log('err') });
}

function pad(pad, str) {
  return (pad + str).slice(-pad.length);
}

function elapsedTime(note){
  var precision = 3;
  var elapsed = process.hrtime(startTime)[1] / 1000000;
  winston.log('info', note + " - " + process.hrtime(startTime)[0] + "s, " + elapsed.toFixed(precision) + "ms");
  startTime = process.hrtime();
}
