#!/usr/bin/env node
'use strict';
// vim: set ft=javascript:

// Examples ffmpeg command: ffmpeg -f image2 -r 5.05555555556 -i out%d.png -y -vcodec libx264 -r 24 -crf 24 test004-1000k-crf24.mp4

var fs = require('fs');
var util = require('util');

var program = require('commander');
var walk = require('walk');
var rmraf = require('rimraf');

program
  .version('0.0.1')
  .option('-d, --directory [path]', 'Change the image directory (default:"images")', 'images')
  .parse(process.argv);

var images = [];
var walker = walk.walk(program.directory, {
  followLinks: false,
  filters: ["Temp", "_Temp", ".git", ".gitkeep"]
});

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

  images = images.concat(nextImages.reverse());
  next();
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

  images = images.reverse()
  var sliceLength = 1000
  var slices = Math.ceil(images.length/sliceLength)
  var slice = []

  var i = 0
  while(i < slices){
    var begin = i*sliceLength
    var end = (i+1)*sliceLength;
    slice = (i < slices-1) ? images.slice(begin, end) : images.slice(begin)
    yield copyImagesToTmp(slice, begin)
    i++
  }
}

var runGenerator = function (fn) {

  return new Promise(function(resolve, reject){
    var next = function (err, arg) {
      if (err) return it.throw(err);

      var result = it.next(arg);
      if (result.done) resolve();

      if (typeof result.value == 'function') {
        result.value(next);
      }
    }

    var it = fn();
    next();
  })
}


walker.on("end", function () {
  runGenerator(copyImagesGenerator).then(function(){
    writeVideo()
  })
});

function run_cmd(cmd, args, callback ) {
  var spawn = require('child_process').spawn;
  var child = spawn(cmd, args, { stdio: ['pipe', 'pipe', 'pipe'] });
  var resp = "";

  child.stdout.on('data', function (buffer) { console.log(buffer) });
  child.stdout.on('end', function() {
    rmraf.sync('./tmp');
    callback('Written '+ images.length + ' images')
  });
  child.stdout.on('error', function() { console.log('err') });
}

function writeVideo(){
  var outputFrameRate = images.length/180
  var inputFrameRate = 1/(180/images.length)
  var args = [
    '-f', 'image2',
    '-r', inputFrameRate,
    '-i', './tmp/out%d.png',
    '-y',
    '-vcodec', 'libx264',
    '-r', '24',
    '-crf', '26',
    '-movflags', 'faststart',
    'latest.mp4'
  ];
  console.log('command: ffmpeg '+ args.join(' '));
  console.time('videoencoding')
  run_cmd(
    'ffmpeg', args, function(text){
      console.timeEnd('videoencoding')
      console.log(text)
    }
  );
}
