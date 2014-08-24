var coffee = require('coffee-script/register');
var gulp = require('gulp');
var mocha = require('gulp-mocha');

var paths = {
	scripts: [ 'src/**/*.coffee' ],
	tests: [ 'test/spec/**/*.spec.js', 'test/spec/**/*.spec.coffee' ],
};

gulp.task('test', function () {
	return gulp.src(paths.tests, {read: false})
		.pipe(mocha({reporter: 'nyan', compilers: 'coffee:coffee-script'}))
		.on('error', function(err) {
			console.log(err.stack);
		});
});

// Rerun the task when a file changes
gulp.task('watch', function() {
	gulp.watch(paths.scripts.concat(paths.tests), ['test']);
});
