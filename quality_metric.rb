class QualityMetric
  attr_reader :name, :story_report

  METRICS_DIR = {
      "viralheat/frontend" => "../../viralheat/frontend/metrics"
  }

  CI_METRICS_DIR = {
      "viralheat/frontend" => "../../#{ENV['JOB']}/workspace/metrics"
  }

  CODE_REPO_DIR = {
      "viralheat/frontend" => "../../viralheat/frontend",
      "viralheat/backend" => "../../viralheat/backend",
      "viralheat/reporter" => "../../viralheat/reporter",
      "viralheat/reports" => "../../viralheat/reports",
      "viralheat/automated-qa" => "../../viralheat/automated-qa",
      "viralheat/no-rails-server" => "../../viralheat/no-rails-server"
  }

  CI_CODE_REPO_DIR = {
      "viralheat/frontend" => "../../development/workspace",
      "viralheat/backend" => "../../backend/workspace",
      "viralheat/reporter" => "../../reporter/workspace",
      "viralheat/reports" => "../../reports/workspace",
      "viralheat/automated-qa" => "../../automated-qa/workspace",
      "viralheat/no-rails-server" => "../../no-rails-server/workspace",
  }


  def initialize(story_report)
    @story_report = story_report
    @name = self.class.name
  end

  def score(repo, file)
    file_score(repo, entry) rescue 0
  end

  def metrics_dir(repo)
    relative = ENV['JOB'].present? ? CI_METRICS_DIR[repo] : METRICS_DIR[repo]
    "#{current_dir}/#{relative}"
  end

  def code_repo_dir(repo = nil)
    relative = ENV['JOB'].present? ? CI_CODE_REPO_DIR[repo] : CODE_REPO_DIR[repo]
    "#{current_dir}/#{relative}"
  end

  def metrics_supported?(repo)
    !METRICS_DIR[repo].blank?
  end

  def missing?(repo, file)
    !(source(repo) && file_entries(repo, file).present?)
  end

  def current_dir
    @current_dir ||= File.expand_path(File.dirname(__FILE__))
  end

  def ci_root(repo)
    ENV['JOB'].present? ? "http://192.168.10.8:8080/job/#{ENV['JOB']}/ws" : current_dir
  end

  def self.class_for(metric_type)
    "Ruby::#{metric_type.to_s.camelize}Metric".constantize
  end


  #def report
  #  {:name => @name, :score => score, :link => link}
  #end
end