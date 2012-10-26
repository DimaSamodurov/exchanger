require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe TZInfo::TimeOrDateTime do
  require 'date'
  require 'timecop'

  describe 'day_order' do
    it 'represents the nth occurrence of the week day in the month' do
      {
       '2012-10-01' => 1,
       '2012-10-07' => 1,
       '2012-10-08' => 2,
       '2012-10-28' => 4,
       '2012-10-29' => 5,
       '2012-10-31' => 5,

       '2012-11-01' => 1,
       '2012-11-04' => 1,
       '2012-11-05' => 1,
       '2012-11-07' => 1,
       '2012-11-08' => 2,
       '2012-11-25' => 4,
       '2012-11-26' => 4,
       '2012-11-29' => 5,
       '2012-11-30' => 5
      }.each do |date, test_value|
        value = TZInfo::TimeOrDateTime.new(DateTime.parse(date)).day_order
        value.should eql(test_value), "Incorrect #day_order for date #{date}: #{value}, but expected #{test_value}."
      end
    end
  end

  # http://msdn.microsoft.com/en-us/library/exchange/aa563445%28v=exchg.140%29.aspx
  describe "standard_time" do
    xit "calculates Standard Time options" do
      time_zone = 'Asia/Baghdad' # tricky because the last transition specified for 2007 (in current version of TZInfo)
      Timecop.travel '2012-06-30' do
        tz = TZInfo::Timezone.get(time_zone).current_period
        p [tz.dst?, tz.start_transition.at, tz.end_transition.at].inspect
        tz.standard_time_options.should be_present
      end

      Timecop.travel '2013-01-31' do
        tz = TZInfo::Timezone.get(time_zone).current_period
        p [tz.dst?, tz.start_transition.at, tz.end_transition.at].inspect
        tz.standard_time_options.should be_present
      end
    end
  end

  # http://msdn.microsoft.com/en-us/library/exchange/aa564336%28v=exchg.140%29.aspx
  describe "daylight_time" do
    xit "calculates Daylight Time options" do
    end
  end
end