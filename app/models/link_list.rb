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

  def fetch_metadata
 	  md = Metadata.new(attributes.slice('ext_id', 'ext_id_type'))
	  md.fetch_metadata
    self.cached_metadata = md.body
    self.title = md.title
    self.publication = md.publication
    self.author = md.author
    self
  end

end
