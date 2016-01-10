require('./style.css');
require('video.js/dist/video-js.css')
var videojs = require('video.js');

var $ = require('npm-zepto');
// var scale = require('./scale');
var playhead = require('./playhead');

var player = {};
var count = 0;

$(document).ready(function(){

  var config = {
    controls : false,
    autoplay : false,
    preload : "auto"
  };

  player = videojs("gtp-video", config);
  player.ready(function(){
    var $playButton = $('.gtp-js-play');

    // Pause because nothing to load yet.
    player.pause();
    // Set dimensions
    setPlayerDimensions(player);
    // Get count.
    getCurrentCount();

    // Player event - loadeddata/video ready.
    player.on('loadeddata', function(){
      player.play();

      $playButton.on('click', function(){
        player.play();
      });
      console.log('loadeddata');

      // Debug
      // player.currentTime(170);
    });

    // Player event - timeupdate/progress
    player.on('timeupdate', function(e){
      // console.log(player.currentTime());
      $playButton.addClass('gtp-btn-play--hidden');
      playhead.updateTime(player.currentTime(), player.duration());
    });

    // Player event - ended/restart
    player.on('ended', onVideoEnd);

    // Event - Fullscreen button.
    var $fsButton = $('.gtp-js-fullscreen');
    $fsButton.on('click', function(){
      // player.requestFullscreen();
      launchFullscreen(document.documentElement);
    });


    // Event - Window resize
    $(window).resize(function(){
      setPlayerDimensions(player);
    })

  });
});

function setPlayerDimensions(player){
  player.width($(window).width());
  player.height($(window).height());
}

function getCurrentCount(){
  $.ajax({
    type: 'GET',
    url: '/count.json',
    // type of data we are expecting in return:
    dataType: 'json',
    success: function(data){
      // Debug
      // count = 324;
      count = data.count;
      setVideo();
      updateImageCount();
      // scale.updateCount(10);
    },
    error: function(xhr, type){
      console.error('Ajax error!')
    }
  })
}

function updateImageCount(){
  var images = pad('00000', count);
  $('.gtp-js-count').text(images);
}

function setVideo(){
  var filename = '/videos/video-'+pad('00000', count)+'.mp4';
  $("source", this.el_).attr("src", filename);
  player.src([
    { type: "video/mp4", src: filename }
  ]);
  player.load();
}

function onVideoEnd(){
  count++;
  getCurrentCount();
}

function pad(pad, str) {
  return (pad + str).slice(-pad.length);
}

function launchFullscreen(element) {
  if(element.requestFullscreen) {
    element.requestFullscreen();
  } else if(element.mozRequestFullScreen) {
    element.mozRequestFullScreen();
  } else if(element.webkitRequestFullscreen) {
    element.webkitRequestFullscreen();
  } else if(element.msRequestFullscreen) {
    element.msRequestFullscreen();
  }
}

function exitFullscreen() {
  if(document.exitFullscreen) {
    document.exitFullscreen();
  } else if(document.mozCancelFullScreen) {
    document.mozCancelFullScreen();
  } else if(document.webkitExitFullscreen) {
    document.webkitExitFullscreen();
  }
}

