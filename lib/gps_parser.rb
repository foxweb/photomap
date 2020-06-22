class GpsParser
  def initialize(file_path)
    @file_path = file_path
  end

  def converted_gps
    return if raw_exif_data.empty?

    {
      latitude:  float_gps(:GPSLatitude, :GPSLatitudeRef),
      longitude: float_gps(:GPSLongitude, :GPSLongitudeRef)
    }
  end

private

  attr_reader :file_path

  # array of raw EXIF GPS data
  def raw_exif_data
    `identify -format '%[exif:GPS*]' #{file_path}`.split("\n")
  end

  # hash of EXIF GPS data
  def exif_data
    @exif_data ||= raw_exif_data.reduce({}) do |result, row|
      name, value = row.split('=')
      key = name.split(':').last
      result.merge(key.to_sym => value)
    end
  end

  # convert GPS coordinates to float
  def float_gps(type, ref)
    deg, min, sec = exif_data[type].split(', ').map(&method(:rational_to_float))
    result = deg + min / 60 + sec / 3600

    # negative value for southern and western hemispheres
    %w[S W].include?(exif_data[ref]) ? -result : result
  end

  # convert string fractions into float
  def rational_to_float(str)
    numerator, denominator = str.split('/')
    Rational(numerator, denominator).to_f
  end
end
