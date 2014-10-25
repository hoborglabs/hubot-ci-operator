_ = require 'lodash'
chai = require('chai');
sinon = require('sinon');
expect = chai.expect;
ciOperatorCreator = require('../../src/ci-operator')

chai.use(require('sinon-chai'));

describe 'ci-operator plugin', ->
	robot = null
	ciOperator = null

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../test_config.json"

	beforeEach ->
		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);

		robot =
			respond: sinon.spy()
			hear: sinon.spy()
			router: {
				post: sinon.stub()
			},
			messageRoom: sinon.spy()

		ciOperator = ciOperatorCreator(robot);

	it 'should listen for post messages', ->
		expect(robot.router.post).to.have.been.calledWith('/hubot/gh-webhook')
		expect(robot.router.post).to.have.been.calledWith('/hubot/jenkins-events')

	describe 'on github pull request notification', ->
		beforeEach ->
			req =
				url: '/hubot/gh-webhook?room=testRoom'
				body: _.merge {}, require('../fixtures/github_pull_request.json')
			res =
				end: sinon.stub()

			ciOperator.github.announcePullRequest = sinon.stub()
					.callsArgWith(1, 'Pull Requst callback')
			ciOperator.jenkins.notifyJenkinsAboutPullRequest = sinon.stub()
					.callsArgWith(2, 'Jenkins Notification callback')

			# post pull request
			robot.router.post.getCall(0).callArgWith(1, req, res);

		it 'should notify room about new pull request', ->
			expect(robot.messageRoom).to.be.calledWith('testRoom', 'Pull Requst callback');

		it 'should notify room about new jenkins job run', ->
			expect(robot.messageRoom).to.be.calledWith('testRoom', 'Jenkins Notification callback');

		it 'should notify Jenkins and Github objects', ->
			expect(ciOperator.jenkins.notifyJenkinsAboutPullRequest).to.be.called
			expect(ciOperator.github.announcePullRequest).to.be.called

	describe 'on jenkins notification', ->
		beforeEach ->
			req =
				url: '/hubot/jenkins-webhook?room=testRoom'
				body: _.merge {}, require('../fixtures/jenkins_notification.json')
			res =
				end: sinon.stub()

			ciOperator.jenkins.announceJenkinsEvent = sinon.stub()
					.callsArgWith(1, 'Jenkins Event callback')
			# ciOperator.github.updatePullRequestStatus = sinon.stub()
			# 		.callsArgWith(1, 'Jenkins Event callback')

			# post jenkins notification
			robot.router.post.getCall(1).callArgWith(1, req, res);

		it 'should notify room about jenkins job result', ->
			expect(robot.messageRoom).to.be.calledWith('testRoom', 'Jenkins Event callback');

		it 'should notify Jenkins and Github objects', ->
			expect(ciOperator.jenkins.announceJenkinsEvent).to.be.called
			# expect(ciOperator.github.updatePullRequestStatus).to.be.called
