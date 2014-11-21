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

  desc "Create an initial admin user for the app."
  task :bootstrap => :environment do
    raise "Already users in the DB, illegal attempt to re-bootstrap" if User.count > 0
    password = SecureRandom::base64.sub(/=+$/, '')
    User.create!(:email => "admin@#{ENV['ROOT_URL']}", :password => password)
    puts <<-DISPLAY
      Admin account created!
      ======================
      Email:    admin@#{ENV['ROOT_URL']}
      Password: #{password}
    DISPLAY
  end
end
