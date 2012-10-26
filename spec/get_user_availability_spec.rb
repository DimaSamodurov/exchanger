require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'timecop'

describe Exchanger::GetUserAvailability do
  describe "Get user availability" do
    let(:valid_attributes) do
      attrs = YAML.load_file("#{File.dirname(__FILE__)}/fixtures/get_user_availability.yml")
      attrs["start_time"] = Time.parse(attrs["start_time"])
      attrs["end_time"] = Time.parse(attrs["end_time"])
      attrs
    end

    let(:response) { Exchanger::GetUserAvailability.run(valid_attributes) }

    it "should be sucessfull with default values" do
      Exchanger::GetUserAvailability.run().status.should == 200
    end

    it "should be sucessfull with valid data" do
      response.status.should == 200
    end

    it "should response have calendar event items" do
      response.items.all?{ |i| i.class.name == "Exchanger::CalendarEvent" }.should be_true
    end

    it "should response have merged free busy merged data" do
      response.merged_free_busy.should_not be_empty
    end

    it "should calendar event item have valid attributes" do
      ["start_time", "end_time", "busy_type", "calendar_event_details"].each do |k|
        response.items[0].attributes.keys.include?(k).should be_true, "missed attribute #{k}"
      end
    end

    it "should calendar event items have calendar event details" do
      response.items.all?{ |i| i.calendar_event_details.class.name == "Exchanger::CalendarEventDetails" }.should be_true
    end

    it "should calendar event details item have valid attributes" do
      ["id","subject","location", "is_meeting", "is_recurring", "is_exception", "is_reminder_set", "is_private"].each do |k|
        response.items[0].calendar_event_details.attributes.keys.include?(k).should be_true
      end
    end

    it "should retrieve data both at Standard Time and Daylight Saving Time periods" do
      verify_request = lambda {
        timezone = 'Europe/Helsinki'
        #tz = TZInfo::Timezone.get(timezone).current_period
        #p [tz.dst?, tz.start_transition.at.to_datetime, p tz.end_transition.at.to_datetime].inspect
        attributes = valid_attributes.dup
        attributes['time_zone'] = timezone
        attributes['start_time'] = Time.now
        attributes['end_time'] = Time.now.advance(:days => 1)
        resp = Exchanger::GetUserAvailability.run(attributes)
        resp.status.should == 200
      }

      Timecop.travel '2012-06-30' do # summer, Daylight Saving Time
        verify_request.call
      end

      Timecop.travel '2012-12-31' do # winter, Standard Time
        verify_request.call
      end
    end
  end
end