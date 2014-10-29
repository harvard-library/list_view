namespace :hl do
  # Batch import expects argument: SRC=$director_name
  desc "Import all xlsx files in provided directory"
  task :batch_import_xlsx => :environment do
    path = File.absolute_path(ENV['SRC'])
    failures = []
    ActiveRecord::Base.transaction do

      Dir.glob(File.join(path, '*.xlsx')).each do |file|
        puts "Processing '#{file}'"
        excel = Roo::Excelx.new(file)
        ll = LinkList.import_xlsx(excel)
        ll.fetch_metadata
        begin
          ll.save!
        rescue
          puts "Failure processing: '#{file}'"
          failures << file
        end
      end

      if failures.length > 0
        puts "Failures:"
        puts failures.map {|el| "\t#{el}"}.join("\n")
        ActiveRecord::Rollback
      end
    end
  end
end
