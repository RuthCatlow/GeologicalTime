require('./style.css');
require('video.js/dist/video-js.css')
var videojs = require('video.js');

var $ = require('npm-zepto');
// var scale = require('./scale');
var playhead = require('./playhead');

var player = null;
var playerStill = null;
var count = 0;
var fullscreenBodyClass = 'is-fullscreen';

$(document).ready(function(){

  fullscreenEvents();

  var config = {
    controls : false,
    autoplay : false,
    preload : "auto"
  };

  if($('#gtp-video-still').length){
    playerStill = videojs("gtp-video-still", config)
    playerStill.ready(function(){
      playerStill.on('loadeddata', function(){
        playerStill.pause();
        //playerStill.currentTime(170);
      });
      playerStill.on('timeupdate', function(){
        playerStill.pause();
      });
      // Set dimensions
      setPlayerDimensions(playerStill);
      // Event - Window resize
      $(window).resize(function(){
        setPlayerDimensions(playerStill);
      })
    });
  }

  var $playButton = $('.gtp-js-play');
  var $fsButton = $('.gtp-js-fullscreen');

  player = videojs("gtp-video", config);
  player.ready(function(){
    $('body').addClass('is-waiting');
    // Pause because nothing to load yet.
    player.pause();
    // Set dimensions
    setPlayerDimensions(player);
    // Get count.
    getCurrentCount();
  });

  // Player event - loadeddata/video ready.
  player.on('loadeddata', function(){
    player.play();
  });

  player.on('timeupdate', function(e){
    // console.log(player.currentTime());
    $playButton.addClass('gtp-btn-play--hidden');
    playhead.updateTime(player.currentTime(), player.duration());
  });

  // Player event - ended/restart
  player.on('ended', onVideoEnd);

  $(window).resize(function(){
    setPlayerDimensions(player);
  })

  $fsButton.on('click', function(){
    $('body').addClass(fullscreenBodyClass);
    if(window.ENV === 'gallery'){
      // player.requestFullscreen();
      launchFullscreen(document.documentElement);
    } else {
      player.requestFullscreen();
    }
  });

  $playButton.on('click', function(){
    console.log('click');
    player.play();
    if(playerStill){
      playerStill.play();
    }
  });

});

function setPlayerDimensions(player){
  var el = player.el().parentNode;
  var style = window.getComputedStyle(el, null);
  // console.log(style);
  player.width(el.offsetWidth);
  player.height(style.height);
}

function getCurrentCount(){
  $.ajax({
    type: 'GET',
    url: '/count.json',
    // type of data we are expecting in return:
    dataType: 'json',
    cache: false,
    success: currentCountSuccess,
    error: function(xhr, type){
      setTimeout(getCurrentCount, 2000);
    }
  })
}

function currentCountSuccess(data){
  // console.log(data.count, count);
  if(data === null || data.count === count){
    $('body').addClass('is-waiting');
    setTimeout(getCurrentCount, 2000);
    return;
  }
  $('body').removeClass('is-waiting');
  // Debug
  // count = 324;
  if(window.FORCE){
    count = window.FORCE;
  } else {
    count = data.count;
  }
  console.log("count:"+count);
  setVideo();
  setImage();
  updateImageCount();
}

function fullscreenEvents(){
  if (document.addEventListener){
    document.addEventListener('webkitfullscreenchange', fullscreenEventHandler, false);
    document.addEventListener('mozfullscreenchange', fullscreenEventHandler, false);
    document.addEventListener('fullscreenchange', fullscreenEventHandler, false);
    document.addEventListener('MSFullscreenChange', fullscreenEventHandler, false);
  }
}

function fullscreenEventHandler(){
  // console.log('event', document.webkitIsFullScreen);
  if (document.webkitIsFullScreen === false || document.mozFullScreen  ===  false || document.msFullscreenElement === false ){
    $('body').removeClass(fullscreenBodyClass);
  } else {
    $('body').addClass(fullscreenBodyClass);
  }
}

function updateImageCount(){
  var images = pad('00000', count);
  $('.gtp-js-count').text(images);
}

function setImage(){
  var filename = '/images/out'+pad('00000', count)+'.png';
  // var bgUrl = "url" + "("  + filename + ")";
  $(".gtp-js-image-still").attr("src", filename);
  $(".gtp-js-image-still").parent().css("background-image", "url("+filename+")");
  $(".gtp-js-image-still").hide();
}

function setVideo(){
  var filename = '/videos/video-'+pad('00000', count)+'.mp4';
  $("source", this.el_).attr("src", filename);
  player.src([
    { type: "video/mp4", src: filename }
  ]);
  player.load();

  if(playerStill){
    playerStill.src([
      { type: "video/mp4", src: filename }
    ]);
    playerStill.load();
  }
}

function onVideoEnd(){
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

