require 'httpi'
require 'nokogiri'
require 'json'
require 'pry'

def get_teams
  all_teams = File.read('./nfl_2018.json')
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

EMPTY_WEEK = {jeff: 0, greg: 0, tim: 0, zach: 0, mike: 0}
CURRENT_NFL_WEEK = 10

def generate_summary_chart
  all_teams = get_teams
  weeklySummary = []
  week1begin = Date.parse('2018-09-06')
  week1end   = Date.parse('2018-09-10')
  CURRENT_NFL_WEEK.times do |i|
    weeklySummary[i] = EMPTY_WEEK.dup
    weekBegin = week1begin.next_day(7*i)
    weekEnd   = week1end.next_day(7*i)
    weeklySummary[i][:weekNum] = i+1
    weeklySummary[i][:dates] = (weekBegin..weekEnd)
  end

  all_teams.each do |team|
    next if team['drafted_by'].empty?
    brother = team['drafted_by'].downcase
    team['wins'].each do |date, wins|
      weeklySummary.each do |summary|
        if summary[:dates].include?(Date.parse(date))
          summary[brother.to_sym] += wins
        end
      end
    end
  end

  allSummaries = []
  allSummaries << weeklySummary.map{ |summary| summary[:jeff] }
  allSummaries << weeklySummary.map{ |summary| summary[:greg] }
  allSummaries << weeklySummary.map{ |summary| summary[:tim] }
  allSummaries << weeklySummary.map{ |summary| summary[:zach] }
  allSummaries << weeklySummary.map{ |summary| summary[:mike] }
  puts allSummaries.to_s
end

def fetch_wins?; true; end;
def write_file?; true; end;

if fetch_wins?
  request = HTTPI::Request.new
  request.url = 'https://www.cbssports.com/nfl/standings/'
  # request.query = { Season: '2015-16',
  #                   SeasonType: 'Regular%20Season'}
  response = HTTPI.get(request)
  full_doc = Nokogiri::HTML(response.body)
  truth_teams = full_doc.xpath('//table[@class="TableBase-table"]/tr')


  all_teams = File.read('./nfl_2018.json')
  all_teams = JSON.parse(all_teams)

  all_teams.each do |team|
    if truth_teams.search("[text()*='#{team['location']}']").first
      wins = truth_teams.search("[text()*='#{team['location']}']").first.parent.parent.parent.parent.parent.children[2].text.to_i
    elsif truth_teams.search("[text()*='#{team['name']}']").first
      wins = truth_teams.search("[text()*='#{team['name']}']").first.parent.parent.parent.parent.parent.children[2].text.to_i
    else
      binding.pry
    end

    team['wins'][Date.today.prev_day.to_s] = wins
  end

  if write_file?
    FileUtils.copy('./nfl_2018.json', "./archive/nfl_#{Date.today}.json")
    File.open('./nfl_2018.json',"w") do |f|
      f.write(all_teams.to_json)
    end
  end
end

generate_team_table
puts '---------------------------||-------------------------'
generate_summary_chart