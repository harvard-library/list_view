class LinkList < ActiveRecord::Base
  belongs_to :continues, :class_name => :link_list
  belongs_to :continued_by, :class_name => :link_list
  has_many :links, -> { order('position ASC')}

  def self.import_xlsx(excel)
    result = LinkList.new

    # Find split between headers and content
    separator = excel.find_index {|row| row[0] == 'CONTENT_LIST'} || raise(StandardError, "No CONTENT_LIST in excel")
    rows = excel.to_a
    (naught, url) = *rows[0]

    raise StandardError, "Initial row must consist of [blank, url], not #{[naught, url]}" unless naught.blank?
    result.url = url
    result.ext_id = url.match(/\d{8,}/)[0]

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
        content
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

    # fetch MODS metadata
    response = HTTParty.get("http://webservices.lib.harvard.edu/rest/mods/#{result.ext_id_type}/#{result.ext_id}",
                            :headers => {"Accept" => "application/json"})
    if response.code == 200
      result.cached_metadata = response.body
    else
      puts "Blarghed out on fetching metadata"
    end

    result
  end

end
