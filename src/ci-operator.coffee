# Description:
#   An HTTP Listener that
#   - notifies about new Github events
#   - notifies about Jenkins events
#
#   Each github pull request can trigger Jenkins build, and each Jenkins build can change status of a pull request.
#
# Dependencies:
#   "url": ""
#   "querystring": ""
#
# Configuration:
#   You will have to do the following:
#   1. Get an API token: curl -u 'username' -d '{"scopes":["repo"],"note":"Hooks management"}' \
#                         https://api.github.com/authorizations
#   2. Add <HUBOT_URL>:<PORT>/hubot/gh-pull-requests?room=<room>[&type=<type>] url hook via API:
#      curl -H "Authorization: token <your api token>" \
#      -d '{"name":"web","active":true,"events":["pull_request"],"config":{"url":"<this script url>","content_type":"json"}}' \
#      https://api.github.com/repos/<your user>/<your repo>/hooks
#
# Commands:
#   None
#
# URLS:
#   POST /hubot/gh-webhook?room=<room>[&type=<type>]
#   POST /hubot/jenkins-events?room=<room>
#
# Authors:
#   hoborglbas
#

url = require('url')
querystring = require('querystring')
Jenkins = require('./ci/jenkins')

module.exports = (robot) ->
	new CiOperator robot

class CiOperator
	constructor: (robot) ->
		@robot = robot
		@config = {}

		if process.env.HUBOT_CIOPERATOR_CONFIG
			@config = require process.env.HUBOT_CIOPERATOR_CONFIG

		@jenkins = new Jenkins @robot, @config

		@robot.router.post "/hubot/gh-webhook", (req, res) =>
			@handleWebhook req, res

		@robot.router.post "/hubot/jenkins-events", (req, res) =>
			@handleJenkinsEvent req, res

	handleWebhook: (req, res) ->
		data = req.body
		query = querystring.parse(url.parse(req.url).query)
		room = query.room

		try
			@announcePullRequest data, (what) =>
				@robot.messageRoom room, what
		catch error
			@robot.messageRoom room, "Whoa, I got an error: #{error}"
			console.log "github pull request notifier error: #{error}. Request: #{req.body}"

		try
			@jenkins.notifyJenkins data, @robot, (what) =>
				@robot.messageRoom room, what
		catch error
			@robot.messageRoom room, "Whoa, I got an error: #{error}"
			console.log "github pull request notifier error: #{error}. Request: #{req.body}"

		res.end ""

	handleJenkinsEvent: (req, res) ->
		data = req.body
		query = querystring.parse(url.parse(req.url).query)
		room = query.room

		try
			@jenkins.announceJenkinsEvent data, (what) ->
				res.messageRoom room, what
		catch error
			@robot.messageRoom room, "Whoa, I got an error: #{error}"
			console.log "jenkins event notifier error: #{error}. Request: #{req.body}"

		res.end ""

	announcePullRequest: (data, cb) ->
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

		cb "New pull request \"#{data.pull_request.title}\" by #{data.pull_request.user.login}: #{data.pull_request.html_url}#{mentioned_line}"
