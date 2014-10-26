'use strict';
var errors = [];

module.exports = {
	catchError: function(stream, err) {
		errors.push(err);
		// console.log('ERROR in ' + err.plugin + ' - ' + err.message);
		stream.emit('end');
	},

	hasErrors: function() {
		return errors.length > 0;
	},

	getErrors: function() {
		for (var i = 0; i < errors.length; i++) {
			console.log('ERROR in ' + errors[i].plugin + ' - ' + errors[i].message);
		}
	}
};
