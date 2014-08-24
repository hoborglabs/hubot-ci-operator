chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;

describe 'ci-operator plugin', ->
	robot = null;

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../test_config.json"

	testCfg = require(process.env.HUBOT_CIOPERATOR_CONFIG);
	jenkinsUrl = testCfg.jenkins.url;

	beforeEach ->
		httpClient =
			get: ->
			put: ->
			post: ->
			header: ->
			query: ->
			path: ->

		sinon.stub(httpClient, method).returns(httpClient) for method in [ "header", "query", "path" ]
		sinon.stub(httpClient, method).returns( (cb) -> cb(null, null, null); ) for method in [ "get", "post", "put" ]

		robot =
			respond: sinon.spy()
			hear: sinon.spy()
			router: {
				post: sinon.stub()
			},
			messageRoom: sinon.spy()
			http: sinon.stub().returns(httpClient)

		require('../../src/ci-operator')(robot);

	it 'should listen for post messages', ->
		expect(robot.router.post).to.have.been.calledWith('/hubot/gh-webhook')
		expect(robot.router.post).to.have.been.calledWith('/hubot/jenkins-events')

	describe 'on pull_request notification', ->

		beforeEach ->
			req =
				url: '/hubot/gh-webhook?room=testRoom'
				body: require('../fixtures/github_pull_request.json')
			res =
				end: sinon.stub()

			# post pull request
			robot.router.post.getCall(0).callArgWith(1, req, res);

		it 'should notify room about new pull request', ->
			expect(robot.messageRoom).to.be.calledWith('testRoom');
			expect(robot.messageRoom.getCall(0).args[1]).to.contain('New pull request')

		it 'should notify room about new jenkins job run', ->
			expect(robot.messageRoom).to.be.calledWith('testRoom');
			expect(robot.messageRoom.getCall(1).args[1]).to.contain('Jenkins Notified')
			expect(robot.messageRoom.getCall(1).args[1]).to.contain('public-repo-build-hash')

		it 'should notify Jenkins', ->
			expect(robot.http.getCall(0).args[0]).to.contain('/job/public-repo-build-hash')
			expect(robot.http.getCall(0).args[0]).to.contain('http://ci.test.company.com')

	describe 'on jenkins notification', ->

		beforeEach ->
			req =
				url: '/hubot/jenkins-webhook?room=testRoom'
				body: require('../fixtures/jenkins_notification.json')
			res =
				end: sinon.stub()

			# post jenkins notification
			robot.router.post.getCall(1).callArgWith(1, req, res);

		it 'should notify room about jenkins job result', ->
			expect(robot.messageRoom).to.be.calledWith('testRoom');
			expect(robot.messageRoom.getCall(0).args[1]).to.contain('Jenkins job')
