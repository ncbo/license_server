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
      [
        @seconds == [ 0 ] ? nil : (@seconds || [ '*' ]).join(','),
        (@minutes || [ '*' ]).join(','),
        (@hours || [ '*' ]).join(','),
        (@monthdays || [ '*' ]).join(','),
        (@months || [ '*' ]).join(','),
        (@weekdays || [ [ '*' ] ]).map { |d| d.compact.join('#') }.join(','),
        @timezone ? @timezone.name : nil
      ].compact.join(' ')
    end
  end
end

