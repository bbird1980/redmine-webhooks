sudo su -
su - redmine
cd /home/redmine/redmine
export RAILS_ENV="production"
bundle exec rake redmine:plugins:migrate
bundle exec rake redmine:plugins:migrate NAME=webhook VERSION=0
ps ax | grep thin | xargs kill
thin -a 127.0.0.1 -p 3000 -P tmp/pids/thin.pid -l log/thin.log -u redmine -g redmine -s 1 -e production -d start
tail -f log/production.log