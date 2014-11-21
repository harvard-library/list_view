# HOLLISLinks

## Description

HOLLISLinks is a tool for creating and maintaining digital objects for serial items (such as journals or magazines) in bibliographic catalogs. It represents these items as a list of links, and has the capacity to fetch MODS metadata describing the item for display purposes.  Records can be created in-tool, or imported via spreadsheets.

## System Requirements

### General

This is a Rails 4.1.x application.  It requires:

* Ruby 2.x
* Bundler
* A webserver capable of running a Rails application.  Tested on Apache and Nginx with Passenger
* An operating system. Tested on Linux/OSX, may work on other platforms.
* A database server. Tested on PostgreSQL 9, should work with other DBs

## Application Set-up Steps
1. Get code from: https://github.com/harvard-library/hollis_links
2. Run `bundle install`.
3. Modify "config/database.yml" and create the database.
4. Create a ".env" file for your environment.  Currently, the following variables are needed to run HOLLISLinks:
  ```
   ROOT_URL=my.hollis.links.host.com
   SECRET_KEY_BASE=ThirtyPlusCharStringOfRandomnessGottenFromRakeSecretMaybe # Only needed in RAILS_ENV=production
   DEVISE_SECRET_KEY=anotherThirtyPluscharStringOfRandomness                 # Also only needed in production
  ```
5. Set up record types and meta-data sources in "config/initializers/metadata_sources.rb"
6. Run bootstrap rake task to set up initial admin user.
  ```Shell
  rake hl:bootstrap
  ```

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

* Bobbi Fox: http://github.com/bobbi_smr
* Dave Mayo: http://github.com/pobocks (primary contact)

## License and Copyright

This application is licensed under the GPL, version 3.

2014 President and Fellows of Harvard College
