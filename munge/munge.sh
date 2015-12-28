#!/usr/bin/env node
// vim: set ft=javascript:

// ffmpeg -f image2 -r 5.05555555556 -i out%d.png -y -vcodec libx264 -r 24 -crf 24 test004-1000k-crf24.mp4

var program = require('commander');
var walk = require('walk');
var fs = require('fs');
var rmraf = require('rimraf');

program
.version('0.0.1')
.option('-d, --directory [path]', 'Change the image directory (default:"images")', 'images')
.parse(process.argv);

var images = [];
var walker = walk.walk(program.directory, {
  followLinks: false,
  filters: ["Temp", "_Temp"]
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

walker.on("names", function (root, nodeNamesArray) {
  nodeNamesArray.sort(function (a, b) {
    if (a > b) return 1;
    if (a < b) return -1;
    return 0;
  });
});

walker.on("files", function (root, stats, next) {
  var nextImages = stats.map(function(file){
    return root + '/' + file.name
  });
  images = images.concat(nextImages.reverse());
  next();
});

walker.on("end", function () {
  images.reverse().forEach(function(file, i){
    var stream = fs.createReadStream(file).pipe(fs.createWriteStream('./tmp/out'+i+'.png'));
    stream.on('finish', function(){
      if(i == images.length-1){
        writeVideo()
      }
    });
  });
});

function run_cmd(cmd, args, callBack ) {
  var spawn = require('child_process').spawn;
  var child = spawn(cmd, args, { stdio: ['pipe', 'pipe', 'pipe'] });
  var resp = "";

  child.stdout.on('data', function (buffer) { console.log(buffer) });
  child.stdout.on('end', function() {
    rmraf.sync('./tmp');
    console.log('Written 226 images')
  });
  child.stdout.on('error', function() { console.log('err') });
}

function writeVideo(){
  var inputFrameRate = 1/(180/images.length);
  var args = [
    '-f', 'image2',
    '-r', inputFrameRate,
    '-i', './tmp/out%d.png',
    '-y',
    '-vcodec', 'libx264',
    '-crf', '24',
    '-movflags', 'faststart',
    'latest.mp4'
  ];
  console.log('command: ffmpeg '+ args.join(' '));
  run_cmd(
    'ffmpeg', args, function(text){ console.log(text) }
  );
}
