chai = require('chai');
sinon = require('sinon');
chai.use(require('sinon-chai'));
expect = chai.expect;
_ = require 'lodash'
configHelper = require '../../config'
githubCreate = require('../../../src/scm/github').create

describe 'Github', () ->
	github = null
	robot = null

	process.env.HUBOT_CIOPERATOR_CONFIG = __dirname + "/../../test_config.json"

	beforeEach () ->
		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);
		robot = {
			respond: sinon.spy(),
			hear: sinon.spy(),
			router: {
				post: sinon.stub()
			},
			messageRoom: sinon.spy(),
			http: sinon.stub()
		};

		github = githubCreate(robot, testCfg);

	describe 'when new pul request comes in', () ->
		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);
		pr = _.merge require('../../fixtures/github_pull_request.json'), {
			action: "opened"
		}

		it 'should be announce as new PR', () ->
			cb = sinon.spy();
			github.announcePullRequest(pr, cb)

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.contain('New pull request');

	describe 'when update to pull request comes in', () ->
		testCfg = _.merge {}, require(process.env.HUBOT_CIOPERATOR_CONFIG);
		pr = _.merge require('../../fixtures/github_pull_request.json'), {
			action: "updated"
		}

		it 'should be announce as update', () ->
			cb = sinon.spy();
			github.announcePullRequest(pr, cb)

			expect(cb).to.be.called;
			expect(cb.getCall(0).args[0]).to.contain('Updated pull request');
