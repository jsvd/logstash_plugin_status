require 'octokit'
require 'pp'
require 'json'
require 'elasticsearch/transport'
require 'time'

def plugin_info client, repo_org, repo_name
  repo_str = "#{repo_org}/#{repo_name}"
  branch = "master"

  rubygems_response = Net::HTTP.get(URI.parse("http://rubygems.org/api/v1/versions/#{repo_name}.json"))
  return if rubygems_response == "This rubygem could not be found."
  rubygems_info = JSON.parse(rubygems_response)
  last_published_gem = rubygems_info.first["number"]
  print "."

  last_commit = client.commits(repo_str, branch).first
  last_tag = client.tags(repo_str).first

  if last_tag
    last_tag_commit = client.commit(repo_str, last_tag.commit.sha)
    print "."

    compare_master_tag = client.compare(repo_str, last_commit.sha, last_tag.commit.sha)
    print "."
  else
    last_tag_commit = nil
    compare_master_tag = nil
  end

  total_issues_open = client.repository(repo_str).open_issues
  pull_requests_open = client.pull_requests(repo_str, :state => "open").size
  issues_open = total_issues_open - pull_requests_open
  print "."

  jenkins_response = Net::HTTP.get(URI.parse("http://build-eu-00.elasticsearch.org/job/#{repo_name.gsub('-', '_').gsub("logstash_", "logstash_plugin_")}/api/json"))
  begin
  jenkins_info = JSON.parse(jenkins_response)
  jenkins_status = (jenkins_info["color"] == "blue") ? "green" : jenkins_info["color"]
  rescue
    jenkins_status = "black"
  end

  print "."

  h = {
    :last_commit_master => last_commit.commit.committer.date.iso8601,
    :last_tag_name => last_tag ? last_tag.name : nil,
    :last_tag_date => last_tag ? last_tag_commit.commit.committer.date.iso8601 : nil,
    :commits_behind => last_tag ? compare_master_tag.behind_by : nil,
    :last_published_gem => last_tag ? last_published_gem : nil,
    :issues_open => issues_open,
    :pull_requests_open => pull_requests_open,
    :jenkins_status => jenkins_status
  }
end

repo_org = "logstash-plugins"

GH_USER=(ENV['GH_USER'] || "")
GH_PWD=(ENV['GH_PWD'] || "")
raise Exception.new("set GH_USER and GH_PWD environment variables") if (GH_USER.empty? || GH_PWD.empty?)

octokit = Octokit::Client.new(:login => GH_USER, :password => GH_PWD)
repos = octokit.org_repos(repo_org, :sort => "name", :per_page => 99)
repos.concat octokit.last_response.rels[:next].get.data

es = Elasticsearch::Client.new

repos.each do |r|
  print "#{r[:name]}"
  h = plugin_info(octokit, repo_org, r[:name])
  next unless h
  h[:last_refresh] = Time.now.iso8601
  response = es.perform_request('POST', "/logstash/plugins/#{r[:name]}", {}, h)
  puts "ok"
end
