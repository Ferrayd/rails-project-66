install:
	bin/setup
	bin/rails assets:precompile

without-production:
	bundle config set --local without 'production'

install-without-production: without-production install
	slim-lint -v || gem install slim_lint
	cp -n .env.example .env || true

start:
	bin/rails s -p 3000 -b "0.0.0.0"

console:
	bin/rails console

test:
	clear || true
	bin/rails db:environment:set RAILS_ENV=test
	NODE_ENV=test bin/rails test

slim-lint:
	slim-lint app/**/*.slim || true

lint: slim-lint
	bundle exec rubocop

lint-fix:
	bundle exec rubocop -A
