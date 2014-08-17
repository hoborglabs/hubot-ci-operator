url = require('url')
querystring = require('querystring')

module.exports = (config) ->
	new Jenkins config

class Jenkins
	constructor: (config) ->
		@config = config
		@jenkinsUrl = @config.jenkins.url

	announceJenkinsEvent: (data, cb) ->
		statusMap = {
			SUCCESS: 'Successfull'
		};

		cb "Jenkins job #{data.name} finished #{statusMap[data.build.status]}. #{data.build.full_url}"

	notifyJenkins: (data, robot, cb) ->
		if data.action != 'opened'
			cb "Pull request ##{data.number} updated"

		pr = data.pull_request
		repoCfg = @config.repos[pr.base.repo.owner.login][pr.base.repo.name]
		head = pr.head.ref
		base = pr.base.ref

		for job in repoCfg.jenkins_jobs[base]
			robot.http("#{@jenkinsUrl}/job/#{job}/buildWithParameters?token=#{@config.jenkins.token}&cause=Pull+Request+#{pr.number}&GIT_SHA=#{pr.head.sha}")
				.get() (err, res, body) ->
					if err
						cb "Encountered an error :( #{err}"
						return
					console.log(body)

			cb "Jenkins Notified - building #{job} (#{head})"
