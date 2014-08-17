chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;

describe('jenkins listiner', function() {
	var jenkins, testCfg;

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../../test_config.json"
	testCfg = require(process.env.HUBOT_CIOPERATOR_CONFIG);

	beforeEach(function() {
		jenkins = require('../../../src/ci/jenkins')(testCfg);
	});

	it('should announce Jenkins Event', function() {
		var cb = sinon.spy();
		var data = require('../../fixtures/jenkins_notification.json')
		jenkins.announceJenkinsEvent(data, cb);

		expect(cb).to.be.called
	})

});
;
