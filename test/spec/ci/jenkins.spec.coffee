chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;
_ = require 'lodash'
configHelper = require '../../config'
createJenkins = require('../../../src/ci/jenkins').create

describe 'Jenkins listiner', () ->
	jenkins = null;
	http = null;
	testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../../test_config.json"

	describe 'when Jenkins job "test-job" exists', ->
		beforeEach () ->
			httpBuild =
				get: ->
			sinon.stub(httpBuild, 'get').returns(
				(cb) -> cb(
					null,
					{ getHeader: sinon.stub().returns('http://192.168.1.129:5080/jenkins/queue/item/5/')},
					''
				);
			);

			httpQueue =
				get: ->
			sinon.stub(httpQueue, 'get').returns( (cb) -> cb(null, {}, {
				executable:
					number: 51,
					url: 'http://192.168.1.129:5080/jenkins/job/test-job/51/'
			}));

			httpJobRun =
				get: ->
			sinon.stub(httpJobRun, 'get').returns( (cb) -> cb(null, {}, {
				number: 51
				duration: 5134,
				url: 'http://192.168.1.129:5080/jenkins/job/test-job/51/',
			}));

			http = sinon.stub()
			http.withArgs(sinon.match(/.*\/job\/test-job\/build.*/)).returns(httpBuild)
			http.withArgs(sinon.match(/.*\/queue\/item\/5\/api\/json/)).returns(httpQueue)
			http.withArgs(sinon.match(/.*\/job\/test-job\/51\/api\/json/)).returns(httpJobRun)

			jenkins = createJenkins(http, testCfg);

		it 'should start a new job', (done) ->
			jenkins.build('test-job', {}, (err, data) ->
				expect(err).to.be.null
				expect(data).to.contain.key('number')
				expect(data.number).to.be.equals(51)
				done()
			)

		it 'should get job data', (done) ->
			jenkins.getJobRun('test-job', 51, (err, data) ->
				expect(err).to.be.null
				expect(data).to.contain.key('number')
				expect(data.number).to.be.equals(51)
				done()
			)

	phasesTests = [
		{
			phases: [ 'STARTED' ]
			ok: [ { phase: 'STARTED', text: 'started' } ]
			notOk: [ 'COMPLETED', 'FINALIZED' ]
		},
		{
			phases: [ 'COMPLETED' ]
			ok: [ { phase: 'COMPLETED', text: 'completed' } ]
			notOk: [ 'STARTED', 'FINALIZED' ]
		},
		{
			phases: [ 'FINALIZED' ]
			ok: [ { phase: 'FINALIZED', text: 'finished' } ]
			notOk: [ 'STARTED', 'COMPLETED' ]
		},
		{
			phases: [ 'all' ]
			ok: [ { phase: 'STARTED', text: 'started' },
				{ phase: 'COMPLETED', text: 'completed' },
				{ phase: 'FINALIZED', text: 'finished' } ]
			notOk: [ ]
		}
	]

	phasesTests.forEach (test) ->
		describe "when phase job configuration specify '#{test.phases}' phase", ->
			beforeEach ->
				testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);
				finder = configHelper.jenkinsJobFinder 'test-job'
				finder(testCfg).jenkins.phases = test.phases

				httpClient =
					get: ->
					put: ->
					post: ->
					header: ->
					query: ->
					path: ->

				sinon.stub(httpClient, method).returns(httpClient) for method in [ "header", "query", "path" ]
				sinon.stub(httpClient, method).returns( (cb) -> cb(null, null, null); ) for method in [ "get", "post", "put" ]

				http = sinon.stub().returns(httpClient)
				jenkins = createJenkins(http, testCfg);

			test.ok.forEach (phase) ->
				it "should announce '#{phase.phase}' events", ->
					cb = sinon.spy();
					data = _.merge {}, require('../../fixtures/jenkins_notification.json');
					data.build.phase = phase.phase

					jenkins.announceJenkinsEvent(data, cb);

					expect(cb).to.be.called;
					expect(cb.getCall(0).args[0]).to.contain('test-job');
					expect(cb.getCall(0).args[0]).to.contain(phase.text);

			for phase in test.notOk
				it "should not announce '#{phase}' event", ->
					cb = sinon.spy();
					data = _.merge {}, require('../../fixtures/jenkins_notification.json');

					data.build.phase = phase
					jenkins.announceJenkinsEvent(data, cb);

					expect(cb).to.be.called;
					expect(cb.getCall(0).args[0]).to.be.empty

	describe 'when job is not in the config', ->
		data = _.merge {}, require('../../fixtures/jenkins_notification.json');
		data.name = 'not-exisitng-job'

		it 'should ignore all notifications', ->
			cb = sinon.spy();

			data.build.phase = 'STARTED'
			jenkins.announceJenkinsEvent(data, cb);

			data.build.phase = 'COMPLETED'
			jenkins.announceJenkinsEvent(data, cb);

			data.build.phase = 'FINALIZED'
			jenkins.announceJenkinsEvent(data, cb);

			expect(cb).to.be.called
			expect(cb.getCall(0).args[0]).to.be.empty
			expect(cb.getCall(1).args[0]).to.be.empty
			expect(cb.getCall(2).args[0]).to.be.empty
