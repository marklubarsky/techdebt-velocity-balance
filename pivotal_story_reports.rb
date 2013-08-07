#!/usr/bin/ruby

# Analyze technical debt and story report
# Author: Mark Lubarsky
# Creation Date: 8/6/2013

# USAGE: JOB=dev_w_metrics ruby pivotal_story_reports.rb

load 'story_report.rb'
StoryReport.publish