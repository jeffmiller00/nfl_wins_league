require 'httpi'
require 'nokogiri'
require 'json'
require 'pry'

def get_teams
  all_teams = File.read('./nba_2018.json')
  JSON.parse(all_teams)
end

def generate_team_table
  all_teams = get_teams
  all_teams.each do |team|
    brother = team['drafted_by'].capitalize
    team_name = team['name']
    weekly_wins = team['wins'].map{ |wins_on| wins_on[1] }
    puts "['#{brother}', '#{team_name}', #{weekly_wins.join(', ')}],"
  end
end

EMPTY_WEEK = {jeff: 0, greg: 0, tim: 0, zach: 0}

def generate_summary_chart
  all_teams = get_teams
  weeklySummary = {}

  all_teams.each do |team|
    next if team['drafted_by'].empty?
    brother = team['drafted_by'].downcase
    team['wins'].each do |date, wins|
      weeklySummary[date.to_s] = EMPTY_WEEK.dup if weeklySummary[date].nil?
      weeklySummary[date.to_s][brother.to_sym] = 0 if weeklySummary[date][brother.to_sym].nil?
      weeklySummary[date.to_s][brother.to_sym] += wins
    end
  end

  allSummaries = []
  allSummaries << weeklySummary.map{ |summary| summary[1][:jeff] }
  allSummaries << weeklySummary.map{ |summary| summary[1][:greg] }
  allSummaries << weeklySummary.map{ |summary| summary[1][:tim] }
  allSummaries << weeklySummary.map{ |summary| summary[1][:zach] }
  puts allSummaries.to_s
end

def fetch_wins?; true; end;
def write_file?; true; end;

if fetch_wins?
  request = HTTPI::Request.new
  request.url = 'http://data.nba.net/data/10s/prod/v1/current/standings_all_no_sort_keys.json'
  # request.query = { Season: '2015-16',
  #                   SeasonType: 'Regular%20Season'}
  response = HTTPI.get(request)
  truth_teams = JSON.parse(response.body)
  truth_teams = truth_teams['league']['standard']['teams']

  all_teams = JSON.parse(File.read('./nba_2018.json'))

  all_teams.each do |team|
    truth_team = truth_teams.select{|t| t["teamId"] == team['teamId'] }.first
    binding.pry if truth_team.empty?

    team['wins'][Date.today.prev_day.to_s] = truth_team['win'].to_i
  end

  if write_file?
    FileUtils.copy('./nba_2018.json', "./archive/nba_#{Date.today}.json")
    File.open('./nba_2018.json',"w") do |f|
      f.write(all_teams.to_json)
    end
  end
end

generate_team_table
puts '---------------------------||-------------------------'
generate_summary_chart