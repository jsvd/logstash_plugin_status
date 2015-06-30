Tool that gives you the status of a logstash plugin. It queries github, rubygems and jenkins to provide:

* when was the last commit
* what is and when was the last tag
* how far is master compared to last tag
* last published gem
* how many issues are open
* how many tags are open
* latest build status from jenkins

It will then write that information to an elasticsearch instance.

For each plugin it collects the following information:

```
{:last_commit_master=>2015-05-05 00:11:11 UTC,
 :last_tag_name=>"v0.2.4",
 :last_tag_date=>2015-04-21 20:34:54 UTC,
 :commits_behind=>5,
 :last_published_gem=>"0.2.4",
 :issues_open=>49,
 :pull_requests_open=>5,
 :jenkins_status=>"green"}
```

Instructions to use:

0. Have an elasticsearch instance running on localhost

1. Populate elasticsearch with plugin status

```
% git clone
% bundle install
% bundle exec ruby get_info.rb
```

2. Generate static html page with plugin status

```
% bundle exec ruby gen_webpage.rb > index.html
```


