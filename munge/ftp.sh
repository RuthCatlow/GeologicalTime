#!/usr/bin/env node
'use strict';
// vim: set ft=javascript

var Client = require('ftp');
require('dotenv').load();

function ftpSend(){
  var options = {
    host: process.env.GTP_HOST,
    user: process.env.GTP_USER,
    pass: process.env.GTP_PASSWORD
  };
  console.log(options);

  var baseDirectory = process.env.GTP_BASE_DIR;

  var c = new Client();
  c.on('ready', function() {
    c.put('foo.txt', baseDirectory+'foo.remote-copy.txt', function(err) {
      if (err) throw err;
      c.end();
    });
  });
	c.connect(options);
}

ftpSend();
