load 'quality_metric.rb'
module Ruby
  class CoverageMetric < QualityMetric
    def file_score(repo, file)
      file_entry(repo, file).first.parent.parent.css('.percent_graph_legend').last.text
    end

    def file_score_link(repo, file)
      "#{ci_root(repo)}/#{file_entry(repo, file).first.parent.css('a').last.attr('href')}"
    end

    def file_code_lines(repo, file)
      file_entry(repo, file).first.parent.parent.css('.right_align').last.text
    end

    def source(repo)
      return nil unless metrics_supported?(repo)

      coverage_file = "#{metrics_dir(repo)}/coverage/rcov/index.html"
      @source ||= Nokogiri.XML(File.open(coverage_file, 'rb')) rescue nil
    end

    def file_entry(repo, file)
      source(repo).css("a:contains('#{file}')")
    end
  end
end