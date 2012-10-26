module TZInfo
  # Extend class defined in TZInfo
  class TimeOrDateTime #:nodoc:
    SECONDS_PER_DAY = 24*60*60
    # Represents the nth occurrence of the day
    # that represents the date of transition from and to standard time and daylight saving time.
    def day_order
      (1..5).detect do |n|
        (self - n*7*SECONDS_PER_DAY).mon < self.mon
      end
    end
  end
end