chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;

describe 'Jenkins listiner', () ->
	jenkins = null;
	robot = null;

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../../test_config.json"
	testCfg = require(process.env.HUBOT_CIOPERATOR_CONFIG);

	beforeEach () ->
		httpClient =
			get: ->
			put: ->
			post: ->
			header: ->
			query: ->
			path: ->

		sinon.stub(httpClient, method).returns(httpClient) for method in [ "header", "query", "path" ]
		sinon.stub(httpClient, method).returns( (cb) -> cb(null, null, null); ) for method in [ "get", "post", "put" ]

		robot = {
			respond: sinon.spy(),
			hear: sinon.spy(),
			router: {
				post: sinon.stub()
			},
			messageRoom: sinon.spy(),
			http: sinon.stub().returns(httpClient),
			end: sinon.stub(),
		};

		jenkins = require('../../../src/ci/jenkins')(robot, testCfg);

	it 'should announce Jenkins Event', () ->
		cb = sinon.spy();
		data = require('../../fixtures/jenkins_notification.json');
		jenkins.announceJenkinsEvent(data, cb);

		expect(cb).to.be.called;
		expect(cb.getCall(0).args[0]).to.contain('notification-plugin');
		expect(cb.getCall(0).args[0]).to.contain('finished successful');

	describe 'when multiple jobs are configured', () ->

		it 'should start each job', () ->
			cb = sinon.spy();
			data = require('../../fixtures/github_pull_request.json');
			jenkins.notifyJenkins(data, robot, cb);
