# coding: utf-8
require 'csv'

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
  has_many :links, -> { order('position ASC')}, :dependent => :destroy
  accepts_nested_attributes_for :links, :reject_if => :all_blank, :allow_destroy => true

  validates :ext_id, :presence => true
  validates :ext_id_type, :presence => true, :inclusion => MetadataSources.keys

  mount_uploader :image, ImageUploader

  after_create do |ll|
    Ledger.create(:event_type => 'create',
                  :user_email => ll.last_touched_by,
                  :ext_id => ll.ext_id,
                  :ext_id_type => ll.ext_id_type,
                  :serialized_linklist => ll.serializable_hash(:include => :links).to_json,
                  :time => ll.created_at)
  end

  after_update do |ll|
    Ledger.create(:event_type => 'update',
                  :user_email => ll.last_touched_by,
                  :ext_id => ll.ext_id,
                  :ext_id_type => ll.ext_id_type,
                  :serialized_linklist => ll.serializable_hash(:include => :links).to_json,
                  :time => ll.updated_at)
  end

  after_destroy do |ll|
    Ledger.create(:event_type => 'destroy',
                  :user_email => ll.last_touched_by,
                  :ext_id => ll.ext_id,
                  :ext_id_type => ll.ext_id_type,
                  :serialized_linklist => ll.serializable_hash(:include => :links).to_json,
                  :time => DateTime.now)
  end

  # Override to force use of ext_id as identifier
  def to_param
    "#{ext_id_type}-#{ext_id}"
  end

  # Get URL for bibliographic record based on template
  def url
    Erubis::Eruby
      .new(MetadataSources[ext_id_type]['templates']['record_url'])
      .result(:ext_id => ext_id, :ext_id_type => ext_id_type)
  end

  # Ephemeral instance var used in audit functionality
  def last_touched_by
    @last_touched_by || '<Admin Console>'
  end

  def last_touched_by=(email)
    @last_touched_by = email
  end

  # Helper for import functions below
  def process_header_field(field)
    (key, content, extra) = *field
    case key
    when /^ext_id_type/i
      raise "Invalid EXT_ID_TYPE" unless MetadataSources.key?(content)
      self.ext_id_type = content
    when /^ext_id/i
      raise "EXT_ID header MUST be preceded by valid EXT_ID_TYPE" unless self.ext_id_type
      self.ext_id = MetadataSources[self.ext_id_type]['id_proc'].call(content)
    when /^continues/i
      self.continues_name = content
      self.continues_url = extra
    when /^continued by/i
      self.continued_by_name = content
      self.continued_by_url = extra
    when /^fts_search/i
      # Regex here is specific to Harvard's FTS search params - portability issues ahoy!
      self.fts_search_url = content.sub(/Q=.*?(&|$)/, '')
    when /^fts_nodate/i
      self.dateable = false
    when key.blank?
    # Nothing
    else
      self.comment = "#{self.comment}\n#{key} #{content}".lstrip
    end
  end

  # Converts from .xlsx format, treating all fields as strings.
  # FIXME: Currently assumes :ext_id_type => 'hollis' (relies on default in DB)
  #        Above applies to CSV import as well
  #
  # Note that indexing starts from 1, because spreadsheets ¯\_(ツ)_/¯
  def self.import_xlsx(excel)
    result = LinkList.new

    # Find split between headers and content ()
    separator = (excel.find_index {|row| row[0] == 'CONTENT_LIST'} + 1) || # array_index + 1 == spreadsheet_index
                raise(StandardError, "No CONTENT_LIST in excel")

    (1...separator).each do |row_i|
      result.process_header_field((1..3).map {|col_i| excel.hl_cell row_i, col_i })
    end

    # process content
    result.links = ((separator+1)..excel.last_row).map do |row_i|
      (label,url) = *((1..2).map {|col_i| excel.hl_cell row_i, col_i })
      Link.new(:name => label, :url => url)
    end

    result
  end

  # Largely identical to above, but CSV is less weird
  # index is zero, everything is a string no matter what
  # Could (should?) probably be refactored into one method
  def self.import_csv(csv)
    result = LinkList.new

    # Find split between headers and content ()
    separator = (csv.find_index {|row| row[0] == 'CONTENT_LIST'}) ||
                raise(StandardError, "No CONTENT_LIST in csv")

    (0...separator).each do |row_i|
      result.process_header_field((0..2).map {|col_i| csv[row_i][col_i]})
    end

    # process content
    result.links = ((separator+1)...csv.count).map do |row_i|
      (label,url) = *((0..1).map {|col_i| csv[row_i][col_i]})
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


  def export_csv
    CSV.generate(:encoding => 'utf-8') do |csv|
      csv << ['EXT_ID_TYPE', ext_id_type]
      csv << ['EXT_ID', ext_id]
      csv << ['FTS_Search', fts_search_url] unless fts_search_url.blank?
      csv << ['FTS_NoDate'] unless dateable?
      csv << ['Continues:', continues_name, continues_url] unless continues_name.blank?
      csv << ['Continued by:', continued_by_name, continued_by_url] unless continued_by_name.blank?
      unless comment.blank?
        comment.lines.each do |line|
          if line.index(':')
            csv << [line[0..line.index(':')], line.sub(/[^:]+?:\s+/, '').chomp]
          else
            csv << [line]
          end
        end
      end
      csv << ['CONTENT_LIST']
      links.each do |link|
        csv << link.attributes.slice(*%w|name url|).values
      end
    end
  end

end
