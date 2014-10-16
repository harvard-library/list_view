class LinkList < ActiveRecord::Base
  has_many :links, -> { order('position ASC')}
  accepts_nested_attributes_for :links, :reject_if => :all_blank, :allow_destroy => true

  class HTTPAsplodeError < StandardError;end

  # NOTE: Cells that can be interpreted as number values will be so interpreted - coercion to string should be forced.
  def self.import_xlsx(excel)
    result = LinkList.new

    # Find split between headers and content
    separator = excel.find_index {|row| row[0] == 'CONTENT_LIST'} || raise(StandardError, "No CONTENT_LIST in excel")
    rows = excel.to_a
    (naught, url) = *rows[0]

    raise StandardError, "Initial row must consist of [blank, url], not #{[naught, url]}" unless naught.blank?
    result.url = url
    result.ext_id = url.match(/\d{8,}/)[0] # throw exception if blank!

    # process headers
    rows[1...separator].each do |(key, content, extra)|
      case key
      when /^continues/i
        result.continues_name = content
        result.continues_url = extra
      when /^continued by/i
        result.continued_by_name = content
        result.continued_by_url = extra
      when /^fts_search/i
        content # Do something here, dude
      when key.blank?
        # Nothing
      else
        result.comment = "#{result.comment}\n#{key} #{content}".lstrip
      end
    end

    # process content
    result.links = rows[(separator+1)...rows.count].map do |(label, url)|
      Link.new(:name => label, :url => url)
    end

    result
  end

  def fetch_metadata
    # fetch MODS metadata
    # NOTES: Status codes need different handling (404 vs 5XX)
    #        Check to make sure there's a reasonable timeout
    #        Location of mods (and possibly structure of call) should be moved to config
    begin
      response = HTTParty.get("http://webservices.lib.harvard.edu/rest/mods/#{ext_id_type}/#{ext_id}",
                              :headers => {"Accept" => "application/json"})
      if response.code == 200 && !response.body.blank?
        cached_metadata = response.body
      else
        raise StandardError, "Failed to fetch metadata"
      end
    rescue StandardError => e
    rescue SocketError => e
      # squelch
    end
  end
end
