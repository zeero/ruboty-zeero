FROM ruby:2.3.1
RUN gem install bundler -v 1.16.1

WORKDIR /usr/src/app
# COPY Gemfile Gemfile.lock vendor/ruboty-zeero .git ./
# COPY Gemfile Gemfile.lock ./
COPY . ./
# throw errors if Gemfile has been modified since Gemfile.lock
ENV BUNDLE_FROZEN=true
RUN bundle install --path vendor/bundle

# COPY . ./

CMD ["bundle", "exec", "ruboty", "--dotenv"]

