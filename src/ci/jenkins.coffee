url = require('url')
querystring = require('querystring')

module.exports = (robot, config) ->
	new Jenkins robot, config

class Jenkins
	constructor: (robot, config) ->
		@robot = robot
		@config = config
		@jenkinsUrl = @config.jenkins.url

	announceJenkinsEvent: (data, cb) ->
		unless @config.jenkins.jobs[data.name]
			return cb ''

		unless data.build.phase in @config.jenkins.jobs[data.name].phases
			return cb ''

		if 'STARTED' == data.build.phase
			return cb "Jenkins job #{data.name} started. #{data.build.full_url}"

		if 'FINALIZED' == data.build.phase
			statusMap = {
				SUCCESS: 'successful'
			};

			return cb "Jenkins job #{data.name} finished #{statusMap[data.build.status]}. #{data.build.full_url}"

		if 'COMPLETED' == data.build.phase
			return cb "Jenkins job #{data.name} completed. #{data.build.full_url}"

		cb ""

	notifyJenkins: (data, robot, cb) ->
		if data.action != 'opened'
			cb "Pull request ##{data.number} updated"

		pr = data.pull_request
		repoCfg = @config.repos[pr.base.repo.owner.login][pr.base.repo.name]

		for job in repoCfg.jenkins_jobs[pr.base.ref]
			this._buildJob job, pr, cb

	_buildJob: (job, pr, cb) ->
		@robot.http("#{@jenkinsUrl}/job/#{job}/buildWithParameters?token=#{@config.jenkins.token}&cause=Pull+Request+#{pr.number}&GIT_SHA=#{pr.head.sha}")
			.get() (err, res, body) ->
				if err
					cb "Encountered an error :( #{err}"
					return

				cb "Jenkins Notified - building #{job} (#{pr.head.ref})"
