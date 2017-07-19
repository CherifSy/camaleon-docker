# Build from the Ruby 2.3 linux image for the base box.
FROM ruby:2.3
MAINTAINER William Payne <will@paynelabs.io>

#Create the directory from which the production code will be hosted
ENV APP_DIR=/var/www/
# Set the rails environment early on, so that all processes are done with production settings
ENV RAILS_ENV=production
RUN mkdir -p $APP_DIR
WORKDIR $APP_DIR

# Cache bundle install
COPY Gemfile $APP_DIR/
COPY Gemfile.lock $APP_DIR/
# When installing Camaleon, you need to have this file included before installing any gems or bundler will fail. This is due to the include statements for building Camaleon plugins.
COPY ./lib/plugin_routes.rb $APP_DIR/lib/

# Bundler also relies on JSON to be able to include the gems from any plugins. JSON must be installed first or bundler will fail. Locked to version 1.8.3 because that's what Camaeleon's Gemfile is locked to.
RUN gem install json -v 1.8.3 --no-rdoc --no-ri
# Install the remaining aspects of the project. Don't install development or test gems because this project is eventually inteded to be used in production.
RUN cd $APP_DIR; bundle install --without development test -j4 

COPY . $APP_DIR/
# Set the environment variable for which Rails will run
ENV RAILS_ENV=production
# Finally, precompile the asset pipeline
RUN bundle exec rake assets:precompile

RUN chown -R nobody:nogroup $APP_DIR
USER nobody

# Publish port 8080, because that's the port that nginx-proxy looks for. Be sure this is configured in your config/puma.rb file if you're recreating this repo.
EXPOSE 8080