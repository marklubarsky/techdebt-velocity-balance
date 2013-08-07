require 'metric_fu'
load 'quality_metric.rb'

module Ruby
  class SaikuroMetric < QualityMetric
    def file_score(repo, file)
      file_totals(file_entry(repo, file))[:complexity]
    end

    def file_score_link(repo, _)
      "#{ci_root(repo)}/metrics/metric_fu/output/saikuro.html"
    end

    def file_code_lines(repo, file)
      file_totals(file_entry(repo, file))[:lines]
    end

    def source(repo)
      return nil unless metrics_supported?(repo)

      metric_file = "#{metrics_dir(repo)}/metric_fu/report.yml"
      @source ||= YAML.load(File.open(metric_file, 'rb')) rescue nil
    end

    def file_entry(repo, file)
      source(repo)[:saikuro][:files].select do |f|
        f[:filename] == file
      end
    end

    def file_totals(entry)
      entry.flatten.first[:classes].inject({:complexity => 0, :lines => 0}) do |acc, klass|
        acc[:complexity] += klass[:complexity]
        acc[:lines] += klass[:lines];
        acc
      end
    end
  end
end