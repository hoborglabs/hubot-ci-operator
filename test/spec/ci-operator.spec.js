chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;

describe('github listiner', function() {
	var robot;
	var testCfg, jenkinsUrl;

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../test_config.json"

	testCfg = require(process.env.HUBOT_CIOPERATOR_CONFIG);
	jenkinsUrl = testCfg.jenkins.url;

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

		require('../../src/ci-operator')(robot);
	})

	it('should listen for post messages', function() {
		expect(robot.router.post).to.have.been.calledWith('/hubot/gh-webhook')
		expect(robot.router.post).to.have.been.calledWith('/hubot/jenkins-events')
	});

	describe('on pull_request notification', function() {

		beforeEach(function() {
			var req = {
				url: '/hubot/gh-webhook?room=testRoom',
				body: require('../fixtures/pull_request.json')
			};

			// post pull request
			robot.router.post.getCall(0).callArgWith(1, req, robot);
		});

		it('should notify room about new pull request', function() {
			expect(robot.messageRoom).to.be.calledWith('testRoom');
			expect(robot.messageRoom.getCall(0).args[1]).to.contain('New pull request')
		});

		it('should notify room about new jenkins job run', function() {
			expect(robot.messageRoom).to.be.calledWith('testRoom');
			expect(robot.messageRoom.getCall(1).args[1]).to.contain('Jenkins Notified')
			expect(robot.messageRoom.getCall(1).args[1]).to.contain('public-repo-build-hash')
		});

		it('should notify Jenkins', function() {
			expect(robot.http.getCall(0).args[0]).to.contain('/job/public-repo-build-hash')
		});
	});

	describe('on jenkins notification', function() {

		beforeEach(function() {
			var req = {
				url: '/hubot/jenkins-webhook?room=testRoom',
				body: require('../fixtures/jenkins_notification.json')
			};
			// post jenkins notification
			robot.router.post.getCall(1).callArgWith(1, req, robot);
		});

		it('should notify room about jenkins job result', function() {
			expect(robot.messageRoom).to.be.calledWith('testRoom');
			expect(robot.messageRoom.getCall(0).args[1]).to.contain('Jenkins job')
		});
	});

});
