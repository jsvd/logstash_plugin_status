require 'octokit'
require 'pp'
require 'json'

client = Octokit::Client.new # (:login => 'user', :password => 'XXXXXXXXXX')

repo_org = "logstash-plugins"
repo_name = ARGV[0] || "logstash-output-elasticsearch"
repo_str = "#{repo_org}/#{repo_name}"
branch = "master"

rubygems_response = Net::HTTP.get(URI.parse("https://rubygems.org/api/v1/versions/#{repo_name}.json"))
rubygems_info = JSON.parse(rubygems_response)
last_published_gem = rubygems_info.first["number"]

last_commit = client.commits(repo_str, branch).first
last_tag = client.tags(repo_str).first
last_tag_commit = client.commit(repo_str, last_tag.commit.sha)

compare_master_tag = client.compare(repo_str, last_commit.sha, last_tag.commit.sha)

total_issues_open = client.repository(repo_str).open_issues
pull_requests_open = client.pull_requests(repo_str, :state => "open").size
issues_open = total_issues_open - pull_requests_open

jenkins_response = Net::HTTP.get(URI.parse("http://build-eu-00.elasticsearch.org/job/#{repo_name.gsub('-', '_').gsub("logstash_", "logstash_plugin_")}/api/json"))
jenkins_info = JSON.parse(jenkins_response)
jenkins_status = (jenkins_info["color"] == "blue") ? "green" : jenkins_info["color"]

h = {
  :last_commit_master => last_commit.commit.committer.date,
  :last_tag_name => last_tag.name,
  :last_tag_date => last_tag_commit.commit.committer.date,
  :commits_behind => compare_master_tag.behind_by,
  :last_published_gem => last_published_gem,
  :issues_open => issues_open,
  :pull_requests_open => pull_requests_open,
  :jenkins_status => jenkins_status
}

pp h
