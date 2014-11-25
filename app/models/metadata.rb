Metadata = Struct.new(:ext_id, :ext_id_type, :body, :title, :author, :publication) do
# a non-persistant view of metadata
  attr_reader :body, :title, :author, :publication
  def initialize(opts, *more)
    if more.length == 0 then
      case
        when  opts.class.to_s == "Hash"
        self.ext_id = opts['ext_id']
        self.ext_id_type = opts['ext_id_type']
      when opts.class.to_s == "Array"
        if opts.length > 0 then
          self.ext_id = opts[0]
          if opts.length > 1 then
            self.ext_id_type = opts[1]
          end
        end
      end
    else
      self.ext_id = opts
      self.ext_id_type = more[0]
    end
      raise ArgumentError.new("ID type can't be nil") if self.ext_id_type.nil?
      raise ArgumentError.new("ID can't be nil") if self.ext_id.nil?

  end
  def source_url
    Erubis::Eruby
      .new(MetadataSources[ext_id_type]['template'])
      .result(:ext_id => ext_id, :ext_id_type => ext_id_type)
  end

  def fetch_metadata
    # fetch MODS metadata
    # NOTES: Status codes need different handling (404 vs 5XX)
    #        Check to make sure there's a reasonable timeout
    begin
      response = HTTParty.get(self.source_url,
                              :headers => {"Accept" => "application/json"})

      if response.code == 200 && !response.body.blank?
        self.body = response.body
        self.populate
      else
        raise StandardError, "Failed to fetch metadata"
      end
    rescue StandardError => e
    rescue SocketError => e
      # squelch
    end
    self.populate
    self
  end

  def process_statement_of_responsibility note
    case note
    when Hash
      if note['type'] == 'statement of responsibility'
        note['content']
      else
        nil
      end
    when Array
      statements = note.select {|n| n.is_a?(Hash) && n['type'] == 'statement of responsibility' }
      statements.first['content'] unless statements.empty?
    when nil
      nil
    end
  end

  def process_name_field name_field
    result = ""
    case name_field
    when Hash
      if name_field['type'].in? %w|personal family corporate conference|
        content = name_field['namePart']
        if content.is_a? Array
          result << content.map do |c|
            c.is_a?(String) ? c : c['content']
          end.join(' ')
        elsif content.is_a? Hash
          result << content['namePart']
        else
          result << content
        end
      end
    when Array
      result += name_field.map{|m| process_name_field m}.join("\n")
    end
    result
  end

  def process_title_field title_field, note = nil
    result = ''
    sor = process_statement_of_responsibility(note)
    case title_field
    when Hash
      result << %w|nonSort title subTitle partNumber partName|.select {|f| title_field.keys.member? f}.map do |f|
        title_field[f]
      end.join(' ')
    when Array
      result << process_title_field(title_field.first)
    end
    "#{result}#{" / " << sor if sor}"
  end

  def process_date_subfield date_sf
    case date_sf
    when Numeric
      date_sf.to_s
    when Array
      if date_sf.first.is_a? String
        date_sf.first
      else
        date_sf.first['content'].to_s.gsub(/\^/, '')
      end
    when Hash
      date_sf['content'].to_s.gsub(/\^/, '')
    else
      nil
    end
  end

  def process_place_subfield place
    if place.is_a? Array
      text = place.select {|pt| pt['placeTerm']['type'] == 'text'}
             .map {|pt| process_placeterm pt['placeTerm']}.reject(&:nil?).join(" ")
      if text.blank?
        text = place.select {|pt| pt['placeTerm']['type'] == 'code'}
               .map {|pt| process_placeterm pt['placeTerm']}.reject(&:nil?).join(" ")
      end
      text
    else
      text = process_placeterm place['placeTerm']
      if text.blank?
        text = 'No place, unknown, or undetermined'
      end
      text
    end
  end

  def process_placeterm pt
    case pt['type']
    when 'text'
      pt['content']
    when 'code'
      if pt['authority'] == 'marccountry'
        "#{ MarcCountryCodes[pt['content'].sub(/\^+/, '')] }"
      else
        nil
      end
    else
      nil
    end
  end

  def process_pub_field pub_field
    result = []
    case pub_field
    when Hash
      publisher = pub_field['publisher'] || 'No listed publisher'
      place =  pub_field['place']       ? process_place_subfield(pub_field['place'])      : nil
      date_i = pub_field['dateIssued']  ? process_date_subfield(pub_field['dateIssued'])  : nil
      date_c = pub_field['dateCreated'] ? process_date_subfield(pub_field['dateCreated']) : nil

      return "#{place.sub(/:\s*\z/, '')} : #{publisher.sub(/,\s*\z/, '')}, #{(date_c || date_i || 'No date of publication provided')}"
    when Array
      pub_field.map {|pf| process_pub_field pf }.join("\n")
    end
  end

  def populate
    md = JSON.parse(body)['mods']
    self.title = process_title_field(md['titleInfo'], md['note']) if md['titleInfo']
    self.author = process_name_field(md['name']) if md['name']
    self.publication = process_pub_field(md['originInfo']) if md['originInfo']
  end

end
