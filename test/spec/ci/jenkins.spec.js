chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;

describe('Jenkins listiner', function() {
	var jenkins, testCfg;

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../../test_config.json"
	testCfg = require(process.env.HUBOT_CIOPERATOR_CONFIG);


	beforeEach(function() {
		robot = {
			respond: sinon.spy(),
			hear: sinon.spy(),
			router: {
				post: sinon.stub()
			},
			messageRoom: sinon.spy(),
			http: sinon.stub().returns({
				get: function() {return sinon.spy(); }
			}),
			end: sinon.stub(),
		};

		jenkins = require('../../../src/ci/jenkins')(robot, testCfg);
	});

	it('should announce Jenkins Event', function() {
		var cb = sinon.spy();
		var data = require('../../fixtures/jenkins_notification.json');
		jenkins.announceJenkinsEvent(data, cb);

		expect(cb).to.be.called;
		expect(cb.getCall(0).args[0]).to.contain('notification-plugin');
		expect(cb.getCall(0).args[0]).to.contain('finished successful');
	})

	describe('when multiple jobs are configured', function() {

		it('should start each job', function() {
			var cb = sinon.spy();
			var data = require('../../fixtures/github_pull_request.json');
			jenkins.notifyJenkins(data, robot, cb);
		})
	});

});
;
