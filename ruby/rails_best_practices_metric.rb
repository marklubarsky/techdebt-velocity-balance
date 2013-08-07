require 'metric_fu'
load 'quality_metric.rb'

module Ruby
  class RailsBestPracticesMetric < QualityMetric
    def file_score(repo, file)
      file_totals(file_entries(repo, file))[:problems]
    end

    def file_score_link(repo, _)
      "#{ci_root(repo)}/metrics/metric_fu/output/rails_best_practices.html"
    end

    def file_secondary_score(repo, file)
      { score: file_totals(file_entries(repo, file))[:uniq_problems], description: 'unique' }
    end

    def source(repo)
      return nil unless metrics_supported?(repo)

      metric_file = "#{metrics_dir(repo)}/metric_fu/report.yml"
      @source ||= YAML.load(File.open(metric_file, 'rb')) rescue nil
    end

    def file_entries(repo, file)
      source(repo)[:rails_best_practices][:problems].select do |f|
        f[:file] == file
      end
    end

    def file_totals(entry)
      { problems: entry.flatten.count, uniq_problems: entry.flatten.map{|e| e[:problem]}.count }
    end
  end
end