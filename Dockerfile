FROM ruby:2.6.2
RUN gem install bundler -v 1.17.2

WORKDIR /usr/src/app
# COPY Gemfile Gemfile.lock vendor/ruboty-zeero .git ./
# COPY Gemfile Gemfile.lock ./
COPY . ./
# throw errors if Gemfile has been modified since Gemfile.lock
ENV BUNDLE_FROZEN=true
RUN bundle install --path vendor/bundle

# COPY . ./

CMD ["bundle", "exec", "ruboty", "--dotenv"]

