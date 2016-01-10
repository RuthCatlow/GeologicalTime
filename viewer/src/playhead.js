var $ = require('npm-zepto');

var canvas = null;
var ctx = null;
var current = 1;
var total = 180;
var bgColour = hexToRgbString('#1f948b', 0.5);

function resizeCanvas() {
  canvas.height = window.innerHeight;
  step();
}

function step() {
  var height = window.innerHeight;
  var pos = current/total;

  ctx.lineWidth = 2;
  ctx.fillStyle = bgColour;
  ctx.strokeStyle = "rgba(255, 0, 0, 1)";
  ctx.clearRect(pos*height, height, canvas.width, height);
  ctx.fillRect(0, 0, canvas.width, height);

  ctx.beginPath();
  ctx.moveTo(0, pos*height);
  ctx.lineTo(canvas.width, pos*height);
  ctx.stroke();

  window.requestAnimationFrame(step);
}

function updateTime(next, duration){
  console.log(next);
  current = next;
  total = duration;
}

function hexToRgbString(hex, alpha) {
  var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  var a = alpha || '1';

  return result
    ? 'rgba('
        + parseInt(result[1],16) +','
        + parseInt(result[2], 16) +','
        + parseInt(result[3], 16) +','
        + a +')'
    : null;
}


$(document).ready(function(){
  canvas = document.getElementById('scale'),
  ctx = canvas.getContext('2d');

  // resize the canvas to fill browser window dynamically
  window.addEventListener('resize', resizeCanvas, false);
  // Start animation loop.
  window.requestAnimationFrame(step);

  resizeCanvas();
});

module.exports = {
  updateTime : updateTime
};
