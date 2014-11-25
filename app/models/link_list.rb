# coding: utf-8

# Monkeypatch for Roo::Excelx because we don't want any floats
class Roo::Excelx
  def hl_cell(row, col, sheet = nil)
    if self.celltype(row, col, sheet) == :float
      self.excelx_value(row, col, sheet)
    else
      self.cell(row, col, sheet)
    end
  end
end

class LinkList < ActiveRecord::Base
  has_many :links, -> { order('position ASC')}
  accepts_nested_attributes_for :links, :reject_if => :all_blank, :allow_destroy => true

  validates :ext_id, :presence => true
  validates :ext_id_type, :presence => true, :inclusion => MetadataSources.keys

  # Override to force use of ext_id as identifier
  def to_param
    "#{ext_id_type}-#{ext_id}"
  end

  # Converts from .xlsx format, treating all fields as strings.
  # Note that indexing starts from 1, because spreadsheets ¯\_(ツ)_/¯
  def self.import_xlsx(excel)
    result = LinkList.new

    # Find split between headers and content ()
    separator = (excel.find_index {|row| row[0] == 'CONTENT_LIST'} + 1) || # array_index + 1 == spreadsheet_index
                raise(StandardError, "No CONTENT_LIST in excel")
    (naught, url) = excel.hl_cell(1,1), excel.hl_cell(1,2)

    raise StandardError, "Initial row must consist of [blank, url], not #{[naught, url]}" unless naught.blank?
    result.url = url
    result.ext_id = url.match(/\d+$/)[0].rjust(9, '0') # throw exception if blank!

    (1...separator).each do |row_i|
      (key, content, extra) = *((1..3).map {|col_i| excel.hl_cell row_i, col_i })
      case key
      when /^continues/i
        result.continues_name = content
        result.continues_url = extra
      when /^continued by/i
        result.continued_by_name = content
        result.continued_by_url = extra
      when /^fts_search/i
        result.fts_search_url = content.sub(/Q=.*?(&|$)/, '')
      when /^fts_nodate/i
        result.dateable = false
      when key.blank?
        # Nothing
      else
        result.comment = "#{result.comment}\n#{key} #{content}".lstrip
      end
    end

    # process content
    result.links = ((separator+1)..excel.last_row).map do |row_i|
      (label,url) = *((1..2).map {|col_i| excel.hl_cell row_i, col_i })
      Link.new(:name => label, :url => url)
    end

    result
  end

  def source_url
    Erubis::Eruby
      .new(MetadataSources[ext_id_type]['template'])
      .result(attributes.slice('ext_id', 'ext_id_type'))
  end

  def fetch_metadata
    # fetch MODS metadata
    # NOTES: Status codes need different handling (404 vs 5XX)
    #        Check to make sure there's a reasonable timeout
    begin
      response = HTTParty.get(source_url,
                              :headers => {"Accept" => "application/json"})

      if response.code == 200 && !response.body.blank?
        self.cached_metadata = response.body
      else
        raise StandardError, "Failed to fetch metadata"
      end
    rescue StandardError => e
    rescue SocketError => e
      # squelch
    end
    self
  end

  def self.process_statement_of_responsibility note
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

  def self.process_name_field name_field
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
      result += name_field.map{|m| LinkList.process_name_field m}.join("\n")
    end
    result
  end

  def self.process_title_field title_field, note = nil
    result = ''
    sor = process_statement_of_responsibility(note)
    case title_field
    when Hash
      result << %w|nonSort title subTitle partNumber partName|.select {|f| title_field.keys.member? f}.map do |f|
        title_field[f]
      end.join(' ')
    when Array
      result << LinkList.process_title_field(title_field.first)
    end
    "#{result}#{" / " << sor if sor}"
  end

  def self.process_date_subfield date_sf
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

  def self.process_place_subfield place
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

  def self.process_placeterm pt
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

  def self.process_pub_field pub_field
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

end
