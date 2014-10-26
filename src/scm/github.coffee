url = require('url')
querystring = require('querystring')

module.exports.create = (robot, config) ->
	new Github robot, config

class Github
	constructor: (robot, config) ->
		@config = config
		@robot = robot
		@github = @config.github.url || 'http://github.com'

	announcePullRequest: (data, cb) ->
		if data.action == 'updated'
			cb "Updated pull request \"#{data.pull_request.title}\" by #{data.pull_request.user.login}: #{data.pull_request.html_url}#{mentioned_line}"

		if data.action == 'opened'
			mentioned = data.pull_request.body?.match(/(^|\s)(@[\w\-\/]+)/g)

			if mentioned
				unique = (array) ->
					output = {}
					output[array[key]] = array[key] for key in [0...array.length]
				value for key, value of output

				mentioned = mentioned.filter (nick) ->
					slashes = nick.match(/\//g)
				slashes is null or slashes.length < 2

				mentioned = mentioned.map (nick) -> nick.trim()
				mentioned = unique mentioned

				mentioned_line = "\nMentioned: #{mentioned.join(", ")}"
			else
				mentioned_line = ''

			return cb "New pull request \"#{data.pull_request.title}\" by #{data.pull_request.user.login}: #{data.pull_request.html_url}#{mentioned_line}"

		cb ""
