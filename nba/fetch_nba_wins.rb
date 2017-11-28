require 'httpi'
require 'nokogiri'
require 'json'
require 'pry'

def get_teams
  all_teams = File.read('./nba_2017.json')
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
      weeklySummary[date][brother.to_sym] += wins
    end
  end

  allSummaries = []
  allSummaries << weeklySummary.map{ |summary| summary[1][:jeff] }
  allSummaries << weeklySummary.map{ |summary| summary[1][:greg] }
  allSummaries << weeklySummary.map{ |summary| summary[1][:tim] }
  allSummaries << weeklySummary.map{ |summary| summary[1][:zach] }
  puts allSummaries.to_s
end

def fetch_wins?; false; end;
def write_file?; true; end;

if fetch_wins?
  request = HTTPI::Request.new
  request.url = 'http://www.espn.com/nba/standings/_/group/league'
  # request.query = { Season: '2015-16',
  #                   SeasonType: 'Regular%20Season'}
  response = HTTPI.get(request)
  full_doc = Nokogiri::HTML(response.body)
  truth_teams = full_doc.xpath('//*[@id="main-container"]/div/section/div[2]/div/div[2]/table/tr')

  all_teams = File.read('./nba_2017.json')
  all_teams = JSON.parse(all_teams)

  all_teams.each do |team|
    binding.pry unless truth_teams.search("[text()*='#{team['name']}']").first
    wins = truth_teams.search("[text()*='#{team['name']}']").first.parent.parent.parent.parent.children[1].text.to_i
    team['wins'][Date.today.prev_day.to_s] = wins
  end

  if write_file?
    FileUtils.copy('./nba_2017.json', "./archive/nba_2017_#{Date.today}.json")
    File.open('./nba_2017.json',"w") do |f|
      f.write(all_teams.to_json)
    end
  end
end

generate_team_table
puts '---------------------------||-------------------------'
generate_summary_chart