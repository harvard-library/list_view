# ListView

## Description

ListView is a tool for creating and maintaining digital objects for serial items (such as journals or magazines) in bibliographic catalogs. It represents these items as a list of links, and has the capacity to fetch MODS metadata describing the item for display purposes.  Records can be created in-tool, or imported via spreadsheets.

## System Requirements

### General

This is a Rails 4.1.x application.  It requires:

* Ruby 2.x
* JRuby 1.7+
* Bundler
* A webserver capable of running a Rails application.  Tested on Apache and Nginx with Passenger
* An operating system. Tested on Linux/OSX, may work on other platforms.
* PostgreSQL 9.2 or greater
* ImageMagick
* A JS runtime supported by the Rails asset pipeline (Node.js, Rhino, etc)

Furthermore, List View displays List Object data from the DRS but requires the following:
* Access to the secure DRS2 Services (for use in displaying List Objects stored in the DRS)
* DRS2 Client Service keys

## Application Set-up Steps
1. Get code from: https://github.com/harvard-library/list_view
2. Run `bundle install`.

   Note: If this fails with a Java `OutOfMemoryError`, you can give the JVM additional memory via JRUBY_OPTS.
   ```Shell
   JRUBY_OPTS=-J-Xmx2048m bundle install
   ```
3. Modify "config/database.yml" and create the database.
4. Modify "config/config.yml" to point to the DRS2 services
5. Create a ".env" file for your environment.  Currently, the following variables are needed to run ListView:

    ```
    ROOT_URL=my.list.view.host.com
    SECRET_KEY_BASE=ThirtyPlusCharStringOfRandomnessGottenFromRakeSecretMaybe # Only needed in RAILS_ENV=production
    DEVISE_SECRET_KEY=anotherThirtyPluscharStringOfRandomness                 # Also only needed in production
    ```
6. Set up record types and meta-data sources in "config/initializers/metadata_sources.rb"
7. Run bootstrap rake task to set up initial admin user.

    ```Shell
    rake hl:bootstrap
    ```

## Dev Notes

Additional development notes are available [here](DEV_NOTES.md).

## Batch import

If you have a collection of CSV files or XLSX files with record info, you can batch upload them by running an included rake task.  Sample data is included in the `test/data` directory of the application.

```Shell
rake batch_import SRC=test/data EMAIL=my.email@address.com
```

SRC should be a directory containing .csv/.xlsx files, or a mixture thereof, each representing one record.  Email should be the email belonging to whomever is ultimately responsible for uploading the records; it can be omitted, in which case a default value representing "random system admin" will be used.

Format for import files located [here](DEV_NOTES.md#user-content-import-format)

## Capistrano

Deployment is beyond the scope of this README, and generally site-specific.  There are example capistrano deployment files that reflect deployment practice at Harvard.

Some basic notes:
* The example files are written with this environment in mind:
  * Capistrano 3+
  * A user install of RVM for ruby management
* Arbitrary rake tasks can be run remotely via the `deploy:rrake` task. Syntax is `cap $STAGE deploy:rrake T=$RAKE_TASK`.  So, to run `rake hl:bootstrap` in the `qa` deploy environment, do:

  ```Shell
  cap qa deploy:rrake T=hl:bootstrap
  ```

## Contributors

* Bobbi Fox: http://github.com/bobbi-SMR
* Dave Mayo: http://github.com/pobocks
* Dee Dee Crema: http://github.com/ives1227 (primary contact)

## License and Copyright

This application is licensed under the GPL, version 3.

2016 President and Fellows of Harvard College
