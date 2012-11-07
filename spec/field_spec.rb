require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Exchanger::Field do
  describe "String (default type)" do
    before do
      @field = Exchanger::Field.new(:full_name)
      @full_name = "Edgars Beigarts"
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.FullName @full_name
      end.doc.root
    end

    it "should convert value to XML" do
      @field.to_xml(@full_name).to_s.gsub(/\n\s*/, "").should == @xml.to_s.gsub(/\n\s*/, "")
    end

    it "should convert XML to value" do
      @field.value_from_xml(@xml).should == @full_name
    end
  end

  describe "String (UID)" do
    before do
      @field = Exchanger::Field.new(:uid, :type => String, :name => "UID")
      @uid = "123"
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.UID @uid
      end.doc.root
    end

    it "should convert value to XML" do
      @field.to_xml(@uid).to_s.gsub(/\n\s*/, "").should == @xml.to_s.gsub(/\n\s*/, "")
    end

    it "should convert XML to value" do
      @field.value_from_xml(@xml).should == @uid
    end
  end

  describe "Integer" do
    before do
      @field = Exchanger::Field.new(:total_count, :type => Integer)
      @total_count = 5
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.TotalCount @total_count
      end.doc.root
    end

    it "should convert value to XML" do
      @field.to_xml(@total_count).to_s.gsub(/\n\s*/, "").should == @xml.to_s.gsub(/\n\s*/, "")
    end

    it "should convert XML to value" do
      @field.value_from_xml(@xml).should == @total_count
    end
  end

  describe "Boolean" do
    before do
      @field = Exchanger::Field.new(:is_read, :type => Exchanger::Boolean)
      @is_read = true
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.IsRead @is_read.to_s
      end.doc.root
    end

    it "should convert value to XML" do
      @field.to_xml(@is_read).to_s.gsub(/\n\s*/, "").should == @xml.to_s.gsub(/\n\s*/, "")
    end

    it "should convert XML to value" do
      @field.value_from_xml(@xml).should == @is_read
    end
  end

  describe "Time" do
    before do
      @field = Exchanger::Field.new(:date_time_sent, :type => Time)
      @date_time_sent_as_str = "2010-05-21T05:57:57Z"
      @date_time_sent = Time.utc(2010, 5, 21, 5, 57, 57)
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.DateTimeSent @date_time_sent_as_str
      end.doc.root
    end

    it "should convert value to XML" do
      @field.to_xml(@date_time_sent).to_s.gsub(/\n\s*/, "").should == @xml.to_s.gsub(/\n\s*/, "")
    end

    describe "value_from_xml" do
      it "should convert XML to value" do
        @field.value_from_xml(@xml).should == @date_time_sent
      end

      context "if zone offset is NOT specified in the xml string"  do
        before do
          @time_string_without_zone = '2010-05-21T05:55:55'
          @xml.stub(:text).and_return(@time_string_without_zone)
        end

        it "should use Time.zone if set (not the system time zone)" do
          ActiveSupport::TimeZone::MAPPING.values.uniq.each do |current_zone|
            Time.use_zone(current_zone) do
              time = @field.value_from_xml(@xml)
              time.should == Time.zone.parse(@time_string_without_zone)
              time.time_zone.name.should == current_zone
            end
          end
        end

        it "should use system time zone if Time.zone is not set" do
          Time.use_zone(nil) do
            time = @field.value_from_xml(@xml)
            time.zone.should == Time.parse(@time_string_without_zone).zone
          end
        end
      end

      context "if zone offset IS specified in the xml string"  do
        context "and Time.zone is set" do
          it "should use Time.zone and time is shifted by the offset value" do
            cet_time_string = '2010-05-21T05:55:55+01:00'
            utc_time = Time.utc(2010, 05, 21, 04, 55, 55)
            @xml.stub(:text).and_return(cet_time_string)

            ActiveSupport::TimeZone::MAPPING.values.uniq.each do |current_zone|
              Time.use_zone(current_zone) do
                time = @field.value_from_xml(@xml)
                time.should == utc_time.in_time_zone
                time.time_zone.name.should == current_zone
              end
            end
          end
        end

        context "and Time.zone is not set" do
          it "should use system Time.zone and time is shifted by the offset value" do
            cet_time_string = '2010-05-21T05:55:55+01:00'
            utc_time = Time.utc(2010, 05, 21, 04, 55, 55)
            @xml.stub(:text).and_return(cet_time_string)

            Time.use_zone(nil) do
              time = @field.value_from_xml(@xml)
              time.should == Time.parse(cet_time_string).localtime
            end
          end
        end
      end
    end
  end

  describe "Array of Physical Addresses" do
    before do
      @field = Exchanger::Field.new(:phone_numbers, :type => [Exchanger::PhysicalAddress])
      @address = Exchanger::PhysicalAddress.new(:street => "Brivibas str.", :city => "Riga", :state => "Latvia")
      @xml = Nokogiri::XML::Builder.new do |xml|
        xml.PhoneNumbers do
          xml.Entry do
            xml.Street @address.street
            xml.City @address.city
            xml.State @address.state
          end
        end
      end.doc.root
    end

    it "should convert value to XML" do
      @field.to_xml([@address]).to_s.gsub(/\n\s*/, "").should == @xml.to_s.gsub(/\n\s*/, "")
    end

    it "should convert XML to value" do
      @field.value_from_xml(@xml).should == [@address]
    end
  end
end
