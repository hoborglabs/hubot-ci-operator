chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;
_ = require 'lodash'

describe 'Jenkins listiner', () ->
	jenkins = null;
	robot = null;

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../../test_config.json"

	beforeEach () ->

		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);

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
		};

		jenkins = require('../../../src/ci/jenkins')(robot, testCfg);

	it 'should announce Jenkins Event', () ->
		cb = sinon.spy();
		data = _.merge {}, require('../../fixtures/jenkins_notification.json');
		data.build.phase = 'FINALIZED'
		jenkins.announceJenkinsEvent(data, cb);

		expect(cb).to.be.called;
		expect(cb.getCall(0).args[0]).to.contain('test-job');
		expect(cb.getCall(0).args[0]).to.contain('finished successful');

	describe 'when phase job configuration specify "STARTED" phase', ->
		`var jenkins`

		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);
		testCfg.jenkins.jobs["test-job"].phases = [ "STARTED" ]
		jenkins = require('../../../src/ci/jenkins')(robot, testCfg);

		it 'should announce "STARTED" events', ->
			cb = sinon.spy();
			data = _.merge {}, require('../../fixtures/jenkins_notification.json');
			data.build.phase = 'STARTED'

			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.contain('test-job');
			expect(cb.getCall(0).args[0]).to.contain('started');

		it 'should not announce other events', ->
			cb = sinon.spy();
			data = _.merge {}, require('../../fixtures/jenkins_notification.json');

			data.build.phase = "COMPLETED"
			jenkins.announceJenkinsEvent(data, cb);

			data.build.phase = "FINALIZED"
			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.be.empty

	describe 'when phase job configuration specify "COMPLETED" phase', ->
		`var jenkins`

		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);
		testCfg.jenkins.jobs["test-job"].phases = [ "COMPLETED" ]
		jenkins = require('../../../src/ci/jenkins')(robot, testCfg);

		it 'should announce "COMPLETED" events', ->
			cb = sinon.spy();
			data = _.merge {}, require('../../fixtures/jenkins_notification.json');
			data.build.phase = 'COMPLETED'

			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.contain('test-job');
			expect(cb.getCall(0).args[0]).to.contain('completed');

		it 'should not announce other events', ->
			cb = sinon.spy();
			data = _.merge {}, require('../../fixtures/jenkins_notification.json');

			data.build.phase = "STARTED"
			jenkins.announceJenkinsEvent(data, cb);

			data.build.phase = "FINALIZED"
			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.be.empty

	describe 'when phase job configuration specify "FINALIZED" phase', ->
		`var jenkins`

		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);
		testCfg.jenkins.jobs["test-job"].phases = [ "FINALIZED" ]
		jenkins = require('../../../src/ci/jenkins')(robot, testCfg);

		it 'should announce "FINALIZED" events', ->
			cb = sinon.spy();
			data = _.merge {}, require('../../fixtures/jenkins_notification.json');
			data.build.phase = 'FINALIZED'

			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.contain('test-job');
			expect(cb.getCall(0).args[0]).to.contain('finished');

		it 'should not announce other events', ->
			cb = sinon.spy();
			data = _.merge {}, require('../../fixtures/jenkins_notification.json');

			data.build.phase = "STARTED"
			jenkins.announceJenkinsEvent(data, cb);

			data.build.phase = "COMPLETED"
			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.be.empty

	describe 'when multiple jobs are configured', () ->

		it 'should start each job', () ->
			cb = sinon.spy();
			data = _.merge {}, require('../../fixtures/github_pull_request.json');
			jenkins.notifyJenkins(data, robot, cb);

	describe 'when job is not in the config', ->
		data = _.merge {}, require('../../fixtures/jenkins_notification.json');
		data.name = 'not-exisitng-job'

		it 'should ignore started notifications', ->
			cb = sinon.spy();
			data.build.phase = 'STARTED'
			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.be.empty

		it 'should ignore completed notifications', ->
			cb = sinon.spy();
			data.build.phase = 'COMPLETED'
			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.be.empty

		it 'should ignore finalised notifications', ->
			cb = sinon.spy();
			data.build.phase = 'FINALIZED'
			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.be.empty
