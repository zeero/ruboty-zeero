FROM ruby:2.6.2
RUN gem install bundler -v 2.1.4

WORKDIR /usr/src/app
# COPY Gemfile Gemfile.lock vendor/ruboty-zeero .git ./
# COPY Gemfile Gemfile.lock ./
COPY . ./
# throw errors if Gemfile has been modified since Gemfile.lock
# ENV BUNDLE_FROZEN=true
RUN bundle config set path 'vendor/bundle'
RUN bundle config set deployment 'true'
RUN bundle install

# COPY . ./

CMD ["bundle", "exec", "ruboty", "--dotenv"]

