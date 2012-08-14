#!/usr/bin/ruby

# Analyze technical debt and velocity for Pivotal project
# Author: Mark Lubarsky
# Creation Date: 8/13/2012

# USAGE: ruby pivotal_technical_debt_velocity_report.rb pivotal_csv_file.csv

require 'rubygems'
require 'fastercsv'
require 'ruby-debug'
require 'active_support/core_ext'

MONTHS = 12
pivotal_csv_file = ARGV[0]

def from_pivotal(file_path)
  #"Story,Labels,Story Type,Current State,Created at,Accepted At,Description,Estimate"
	"Story,Labels,Story Type,Current State,Created at,Accepted at,Description,Estimate"
	FasterCSV.read(file_path, { :headers           => true })
end

def month_data(month, attr_array)
  attr_array.select do |row|
    date = row["Accepted at"] || row["Delivered at"] || row["Created at"]
    Time.parse(date).between?(month.beginning_of_month, month.end_of_month)
  end
end

def summarize(attr_array, status_array)
  attr_array = attr_array.select {|row| status_array.include?(row["Current State"])}

  {:stories => attr_array.count,
   :point_features => attr_array.select { |row| row["Estimate"].to_i > 0}.count,
   :points => attr_array.sum { |row| row["Estimate"].to_i },
   :no_point_features => attr_array.select { |row| row["Estimate"].to_i == 0}.count,
   :bugs => attr_array.select { |row| row["Story Type"] == "bug"}.count,
   :chores => attr_array.select { |row| row["Story Type"] == "chore"}.count,
  }
end

def monthly_summary(attr_array, num_of_months=MONTHS)
  (1..num_of_months).inject([]) do |months, month|
    month = Time.now - (month - 1) * 1.month # go back N months
    summary = {:accepted => summarize(month_data(month, attr_array), ["accepted"])}.merge(:month => month.strftime("%B %Y"))
    summary.merge!(:outstanding => summarize(month_data(month, attr_array), ["delivered","finished","unstarted","started","rejected"]))
    months << summary
    months
  end
end

pivotal_attr_array = from_pivotal(pivotal_csv_file)
summary = monthly_summary(pivotal_attr_array)

puts "=" * 30
puts "Summary of #{pivotal_csv_file} for last #{MONTHS} months (as of #{Time.now.strftime('%B %d, %Y %I:%M%p')}):"

summary.select{|s| s[:accepted][:stories].to_i > 0 || s[:outstanding][:stories].to_i > 0}.each do |month_summary|
  puts "=" * 30
  puts "MONTH:#{month_summary[:month].inspect}"
  puts "TOTAL:#{month_summary[:accepted][:stories]} accepted stories, #{month_summary[:outstanding][:stories]} outstanding"
  puts "Point Features:#{month_summary[:accepted][:point_features]} accepted (#{month_summary[:accepted][:points]} points accepted), #{month_summary[:outstanding][:point_features]} outstanding (#{month_summary[:outstanding][:points]} points outstanding)"
  puts "0-point Features:#{month_summary[:accepted][:no_point_features]} accepted, #{month_summary[:outstanding][:no_point_features]} outstanding"
  puts "Bugs:#{month_summary[:accepted][:bugs]} accepted, #{month_summary[:outstanding][:bugs]} oustanding"
  puts "Chores:#{month_summary[:accepted][:chores]} accepted, #{month_summary[:outstanding][:chores]} oustanding"
  puts "=" * 30
end







