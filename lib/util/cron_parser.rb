require 'ruby-xxhash'

module CronParser
  class Cron < Fugit::Cron
    attr_writer(:seconds, :minutes, :hours, :monthdays, :months, :weekdays, :timezone)

    class << self
      def minutes_from_string(str)
        seed = 1212
        min = ((XXhash.xxh32(str, seed)/1000).to_i/60000).to_i
        min -= 60 while min >= 60
        min
      end
    end

    def to_cron_s
      remove_instance_variable(:@cron_s)
      super
    end
  end
end