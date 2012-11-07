module Exchanger
  # Getting User Availability
  # 
  # http://msdn.microsoft.com/en-us/library/aa564001%28EXCHG.80%29.aspx
  class GetUserAvailability < Operation
    class Request < Operation::Request
      attr_accessor :time_zone, :email_address, :start_time, :end_time, :freebusy_interval, :requested_view

      # Reset request options to defaults.
      def reset
        @time_zone = 'Europe/London'
        @email_address = 'test.test@test.com'
        @start_time = Date.today.to_time + 1
        @end_time = (Date.today + 1).to_time - 1
        @freebusy_interval = 60
        @requested_view = 'DetailedMerged'
      end

      def time_zone_period
        begin
          current_tz = TZInfo::Timezone.get(time_zone).current_period
        rescue => e
          raise Exchanger::Operation::ResponseError.new(e, 500)
        end
      end

      def to_xml
        current_tz = time_zone_period
        minutes_of_utc_offset = current_tz.utc_offset/60 # Get the base offset of the timezone from UTC in minutes
        minutes_of_std_offset = current_tz.std_offset/60 # Get the daylight savings offset from standard time in minutes

        start_date_time = start_time.strftime("%Y-%m-%dT%H:%M:%S")
        end_date_time = end_time.strftime("%Y-%m-%dT%H:%M:%S")

        Nokogiri::XML::Builder.new do |xml|
          xml.send("soap:Envelope", "xmlns:xsi" => NS["xsi"], "xmlns:xsd" => NS["xsd"], "xmlns:soap" => NS["soap"], "xmlns:t" => NS["t"], "xmlns:m" => NS["m"]) do
            xml.send("soap:Body") do
              xml.send("m:GetUserAvailabilityRequest") do
                xml.send("t:TimeZone") do
                  xml.send("t:Bias", (minutes_of_utc_offset * -1))
                  # if daylight savings time is active for current time zone
                  # How to find correct standard time and daylight saving time configuration

                  # StandardTime (and) DaylightTime are required parts of TimeZone.
                  # If we don't provide this info we will get error:
                  #   The request failed schema validation: The element 'TimeZone' in namespace
                  #   'http://schemas.microsoft.com/exchange/services/2006/types' has incomplete content.
                  #   List of possible elements expected: 'StandardTime' in namespace
                  #   'http://schemas.microsoft.com/exchange/services/2006/types'.
                  # TODO calculate standard time and daylight saving time configuration for current period
                  #if current_tz.dst?
                    xml.send("t:StandardTime") do
                      xml.send("t:Bias", 0)
                      xml.send("t:Time", "04:00:00")
                      xml.send("t:DayOrder", 5)
                      xml.send("t:Month", 10)
                      xml.send("t:DayOfWeek", "Sunday")
                    end
                    xml.send("t:DaylightTime") do
                      xml.send("t:Bias", (minutes_of_std_offset * -1))
                      xml.send("t:Time", "03:00:00")
                      xml.send("t:DayOrder", 5)
                      xml.send("t:Month", 3) # current_tz.end_transition.at.mon
                      xml.send("t:DayOfWeek", "Sunday")
                    end
                  #end
                end
                xml.send("m:MailboxDataArray") do
                  [email_address].flatten.each do |email_address|
                    xml.send("t:MailboxData") do
                      xml.send("t:Email") do
                        xml.send("t:Address", email_address)
                      end
                      xml.send("t:AttendeeType", "Required")
                      xml.send("t:ExcludeConflicts", "false")
                    end
                  end
                end
                xml.send("t:FreeBusyViewOptions") do
                  xml.send("t:TimeWindow") do
                    xml.send("t:StartTime", start_date_time)
                    xml.send("t:EndTime", end_date_time)
                  end
                  xml.send("t:MergedFreeBusyIntervalInMinutes", freebusy_interval)
                  xml.send("t:RequestedView", requested_view)
                end
              end
            end
          end
        end
      end
    end

    class Response < Operation::Response
      def items
        to_xml.xpath(".//t:CalendarEventArray", NS).children.map do |node|
          item_klass = Exchanger.const_get(node.name)
          item_klass.new_from_xml(node)
        end
      end

      def merged_free_busy
        to_xml.xpath(".//t:MergedFreeBusy", NS).text()
      end

      def multiple_mailbox_items
        to_xml.xpath("//m:FreeBusyResponseArray", NS).children.map do |node|
          next if Exchanger::Element.blank_node?(node)
          node.xpath(".//t:CalendarEventArray", NS).children.map do |node|
            next if Exchanger::Element.blank_node?(node)
            item_klass = Exchanger.const_get(node.name)
            item_klass.new_from_xml(node)
          end.compact
        end.compact
      end
    end
  end

end