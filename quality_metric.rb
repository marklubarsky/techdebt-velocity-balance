class QualityMetric
  attr_reader :name, :story_report

  METRICS_DIR = {
      "viralheat/frontend" => "../../viralheat/frontend/metrics"
  }

  CODE_REPO_DIR = {
      "viralheat/frontend" => "../../viralheat/frontend",
      "viralheat/backend" => "../../viralheat/backend",
      "viralheat/reporting" => "../../viralheat/reporting",
      "viralheat/reports" => "../../viralheat/reports",
  }

  CI_CODE_REPO_DIR = {
      "viralheat/frontend" => "../../development",
      "viralheat/backend" => "../../backend",
      "viralheat/reporting" => "../../reporting",
      "viralheat/reports" => "../../reports",
  }


  def initialize(story_report)
    @story_report = story_report
    @name = self.class.name
  end

  def score(repo, file)
    file_score(repo, entry) rescue 0
  end

  def metrics_dir(repo)
    "#{current_dir}/#{METRICS_DIR[repo]}"
  end

  def code_repo_dir(repo = nil)
    relative = ENV['JOB'].present? ? CI_CODE_REPO_DIR[repo] : CODE_REPO_DIR[repo]
    "#{current_dir}/#{relative}"
  end

  def metrics_supported?(repo)
    !METRICS_DIR[repo].blank?
  end

  def missing?(repo, file)
    !(source(repo) && file_entry(repo, file).present?)
  end

  def current_dir
    @current_dir ||= File.expand_path(File.dirname(__FILE__))
  end

  def ci_root(repo)
    ENV['JOB'].present? ? "http://192.168.10.8:8080/job/#{ENV['JOB']}/ws" : current_dir
  end

  def self.class_for(metric_type)
    "Ruby::#{metric_type.to_s.capitalize}Metric".constantize
  end


  #def report
  #  {:name => @name, :score => score, :link => link}
  #end
end