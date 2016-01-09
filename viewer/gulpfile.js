var gulp = require('gulp');
var gutil = require('gulp-util');
var ftp = require('vinyl-ftp');

require('dotenv').load({path:'../munge/.env'});

gulp.task('default', function () {
  var conn = ftp.create( {
    host: process.env.GTP_HOST,
    user: process.env.GTP_USER,
    password: process.env.GTP_PASSWORD,
    parallel: 10,
    log:      gutil.log
  });

	var globs = [
		'dist/*.css',
		'dist/*.js',
		'index.html'
	];

  var baseDirectory = process.env.GTP_BASE_DIR;
  console.log(baseDirectory);
	return gulp.src( globs, { base: '.', buffer: false } )
			.pipe( conn.dest( baseDirectory ) );
});
