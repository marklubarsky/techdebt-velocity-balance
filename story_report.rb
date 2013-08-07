require 'pivotal_tracker'
require 'active_support/core_ext'

load 'ruby/coverage_metric.rb'
load 'ruby/saikuro_metric.rb'
load 'ruby/rails_best_practices_metric.rb'

#p (load 'story_report.rb') && (reports=StoryReport.recent).last.report
class StoryReport

  def self.supported_metrics(platform)
    if platform == :ruby
      [:coverage, :saikuro, :rails_best_practices]
    else
      []
    end
  end

  attr_reader :csv_hash, :story
  attr_reader *StoryReport.supported_metrics(:ruby)

  API_TOKEN = 'c614d0c794183a6943f8034f32a7b32e'
  PivotalTracker::Client.token = API_TOKEN

  PROJECT = 528259


  def initialize(data)
    @story = data[:story]
    @csv_hash = data[:csv]
    #require 'debugger';debugger
    StoryReport.supported_metrics(:ruby).map do |metric_type|
     instance_variable_set("@#{metric_type.to_s}", QualityMetric.class_for(metric_type).new(self))
    end
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

  def summary
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
    cmd = "cd #{coverage.code_repo_dir(repo)}; git show --no-commit-id --name-only #{commit}"
    puts "processing commit #{commit}, repo: #{repo}"
    `#{cmd}`.split("\n")
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
                       secondary_score: metric.file_secondary_score(repo, file)
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
    end.flatten.uniq
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

  def self.publish
    StoryReport.recent.each do |report|
      files = report.touched_files
      files_str = files.map do |file|
        metric_str = supported_metrics(:ruby).map do |metric_type|
          metric = file[metric_type]
          ((metric == 'missing') ? nil : "#{metric_type.upcase}: [#{metric[:score]}(#{metric[:secondary_score][:score]} #{metric[:secondary_score][:description]}) - #{metric[:link]} ]")
        end.compact.join(",")
        metric_str = metric_str.present? ? "(#{metric_str})" : ''
        "#{file[:file]}:#{metric_str}"
      end.join("\n\n")

      str = <<-REPORT
        This story involved changes to #{files.count} files via #{report.commits.count} commits:

        #{files_str}
      REPORT

      begin
        if (str.slice(0,20000) == report.comments.last)
          puts "WARNING:Story #{report.story.id} has not changed since the last report was made, skipping..."
        else
          puts "Generating a report for Story #{report.story.url} '#{report.story.name}' (#{report.commits.count} commits, #{report.touched_files.count} affected files)."
          report.story.notes.create(:text => str)
        end
      rescue RestClient::UnprocessableEntity => e
        puts "WARNING:Story #{report.story.id} has too many changes to fit in a comment (#{str.length} characters), truncating..."
        report.story.notes.create(:text => str.slice(0,20000))
      end
    end
  end

  def self.find(story_id)
    recent.detect {|report| report.story.id == story_id }
  end

  def self.recent(reload=false)
    if reload
      @@project = nil
      @@stories = nil
    end

    label = ENV['STORY_FILTER']

    state = ['finished','delivered']
    story_type = ['feature', 'bug']

    if label
      story_type = ['chore', 'bug', 'feature']
      state = ['started','finished','delivered']
    end

    @@project ||= PivotalTracker::Project.find(PROJECT)
    filters = { modified_since: (Time.now - 2*24*60*60).strftime('%d/%m/%Y') }

    filters.merge!(label: label) if label
    filters.merge!(current_state: state) if state
    filters.merge!(story_type: story_type) if story_type

    @@stories ||= @@project.stories.all(filters)
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

