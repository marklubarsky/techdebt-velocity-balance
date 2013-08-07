require 'pivotal_tracker'
require 'active_support/core_ext'

load 'ruby/coverage_metric.rb'
load 'ruby/saikuro_metric.rb'

#p (load 'story_report.rb') && (reports=StoryReport.recent).last.report
class StoryReport

  attr_reader :csv_hash, :story, :coverage, :saikuro

  API_TOKEN = 'c614d0c794183a6943f8034f32a7b32e'
  PivotalTracker::Client.token = API_TOKEN

  PROJECT = 528259


  def initialize(data)
    @story = data[:story]
    @csv_hash = data[:csv]
    #require 'debugger';debugger
    @coverage = Ruby::CoverageMetric.new(self)
    @saikuro = Ruby::SaikuroMetric.new(self)
  end

  def name
    csv_format? ? csv_hash["Story"] : story.name
  end

  def url
    csv_format? ? csv_hash["URL"] : story.url
  end

  def comments
    if csv_format?
      csv_hash.entries.select {|field| field[0] == "Comment"}.map { |comment| comment[1]}
    else
      story.notes.all.map(&:text)
    end.compact.reject {|c| c.empty?}
  end

  def report
    authors = commits.map {|commit| commit_author(commit) }.uniq

    report = {
        :story => name,
        :url => url,
        #:comments => csv_hash_comments(csv_hash),
        :commits => commits,
        :author => authors,
        :files => touched_files,
        :scores => scores
    }
    report[:commits] = nil unless report[:commits].present?
    report[:author] = nil unless report[:author].present?
    report[:files] = nil unless report[:files].present?
    report
  end

  def commits
    comments.map do |comment|
      comment =~ /github.com\/(.*)\/commit\/(\S*)/
      {:repo => $1, :commit => $2}
    end.select {|commit| commit.values.compact.present? }.compact
  end

  def commit_details(commit)
    #--pretty="format:"
    #return [] if commit.blank?
    repo, commit = commit[:repo], commit[:commit]
    `cd #{coverage.code_repo_dir(repo)}; git show --no-commit-id --name-only #{commit}`.split("\n")
  end

  def commit_files(commit)
    commit_details(commit)[0...-5]
  end

  def commit_author(commit)
    commit_details(commit)[-4]
  end

  def file_details(repo, file)
    hash = {
        :file => file,
        :repo => repo
    }
    StoryReport.supported_metrics(:ruby).map do |metric_type|

      metric = metric_instance(metric_type)
      metric_hash = if metric.missing?(repo, file)
                     'missing'
                    else
                     {
                       score: metric.file_score(repo, file),
                       link: metric.file_score_link(repo, file),
                       lines: metric.file_code_lines(repo, file)
                     }
      end

      hash.merge!(metric_type => metric_hash)
      hash
    end
  end

  def touched_files
    commits.map do |commit|
      commit_files(commit).flatten.compact.uniq.map do |file|
        file_details(commit[:repo], file)
      end
    end.flatten
  end

  def scores
    StoryReport.supported_metrics(:ruby).map do |metric_type|
      {
        metric_type => touched_files.inject(0) do |score, file_info|
          metric = metric_instance(metric_type)
          if !metric.missing?(file_info[:repo], file_info[:file])
            score += file_info[metric_type][:score]
          end
          score
        end
      }
    end
  end

  def self.supported_metrics(platform)
    if platform == :ruby
      [:coverage, :saikuro]
    else
      []
    end
  end

  def self.recent(reload=false)
    if reload
      @@project = nil
      @@stories = nil
    end

    @@project ||= PivotalTracker::Project.find(PROJECT)
    @@stories ||= @@project.stories.all(modified_since: (Time.now - 2*24*60*60).strftime('%d/%m/%Y'), current_state: ['finished','delivered'])
    @@stories.map {|story| StoryReport.new(story: story)}
  end

  private
  def csv_format?
    story.nil?
  end

  def metric_instance(metric_type)
    self.send(metric_type)
  end
end

