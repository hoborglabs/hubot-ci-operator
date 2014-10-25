
exports.jenkinsJobFinder = (jobName)->
	(cfg) ->
		for job in cfg.jobs
			return job if job.jenkins.job == jobName
