#!/usr/bin/env bash
# http://www.mfernandez.es/ci

export RUBY_VER=2.1.1
export CHEF_SERVER_VER=11.0.12
export GEM_DEPENDS="bundler ohai"
export CHEF_REPO_NAME='gecoscc-chef-server-repo'
export CHEF_REPO_URL="https://gitlab.mfernandez.es/repository/ci.git"


# Define Nexus Configuration
NEXUS_BASE=http://repository.example.com:8081/nexus
REST_PATH=/service/local
ART_REDIR=/artifact/maven/redirect

./functins.sh

# Setting hosts
IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
HOSTNAME=`hostname | awk '{print tolower($0)}'`
echo "$IP $HOSTNAME" >> /etc/hosts

cat /etc/*release

# if we are in a "yum-able" system, install EPEL depend needed for 'rvm' install
which yum && yum install -y http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

# Inserted Recipe(s) will be processed
[ ! "$#" -ge 1 ] && echo "[ERROR]: Missing Parameter (-1) - exiting..." && exit 1
myArray=( "$@" )
for ((index=0; index<${#myArray[@]}; index++)); do
        [ $index -eq 0 ] && RECIPES="\"recipe[${myArray[$index]}]\"" && continue
        RECIPES+=,\"recipe[${myArray[$index]}]\"
done
echo "These recipes will be processed:" $RECIPES

#delete older trustdb.gpg
rm $HOME/.gnupg/trustdb.gpg
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -

# install rvm and ruby
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh 
rvm reload
rvm install ruby-$RUBY_VER
rvm use --default ruby-$RUBY_VER
gem install $GEM_DEPENDS --no-ri --no-rdoc

# install git
PLATFORM=$(ohai |grep platform_family|awk -F: '{print $2}'|sed 's|[", ]||g')

case $PLATFORM in
  "rhel")
    yum install -y git
    ;;
  "debian")
    apt-get install -y git
    ;;
  *)
    echo "Platform not supported! Only 'rhel' and 'debian' are."
    echo "yes" | rvm implode
    exit 0
    ;;
esac


# create chef-solo config
cat > /tmp/solo.rb << EOF
	root = File.absolute_path(File.dirname(__FILE__))
	file_cache_path root
	cookbook_path root + '/${CHEF_REPO_NAME}/cookbooks'
EOF

# create node's json
cat > /tmp/solo.json << EOF
{
    "run_list": [ $RECIPES ],
    "gecoscc-chef-server": {
        "chef-server-version": "$CHEF_SERVER_VER"
    }
}
EOF

# cleanup tmp dirs just in case there were any from older intallation tries
LOCAL_CHEF_REPO="/tmp/${CHEF_REPO_NAME}"
test -d $LOCAL_CHEF_REPO && rm -rf $LOCAL_CHEF_REPO

# download chef-repo
git clone $CHEF_REPO_URL $LOCAL_CHEF_REPO
cd $LOCAL_CHEF_REPO
bundle install
git submodule init
git submodule update
for cookbook in cookbooks/*
do
  cd $cookbook
  test -f Berksfile && berks install
  cd -
done
cd

# link berks installed cookbooks to cookbook path removing version
for cookbook in /root/.berkshelf/cookbooks/*
do
  ln -s $cookbook $LOCAL_CHEF_REPO/cookbooks/$(echo $cookbook | sed 's|\(.*\)\(-.*\)|\1|g'|xargs basename)
done

# install software via cookbooks
chef-solo -c /tmp/solo.rb -j /tmp/solo.json 

## finish chef-server installation
chef-server-ctl reconfigure

if [ $? -eq 0 ]; then
	chef-server-ctl test
	[ $? -eq 0 ] && echo -e "[ERROR] \"chef-server-ctl reconfigure\" command FAILED... " &&	exit 1
else
	echo -e "[ERROR] \"chef-server-ctl reconfigure\" command FAILED... " &&	exit 1
fi


# configure knife.rb

cat > /tmp/knife.rb << EOF
log_level                :info
log_location             STDOUT
node_name                'admin'
client_key               '/etc/chef-server/admin.pem'
validation_client_name   'chef-validator'
validation_key           '/etc/chef-server/chef-validator.pem'
chef_server_url          'https://localhost:443/'
syntax_check_cache_path  '/root/.chef/syntax_check_cache'
cookbook_path            '${LOCAL_CHEF_REPO}/cookbooks'
EOF

# upload all the cookbooks
knife cookbook upload -c /tmp/knife.rb -a

# remove temporal rvm installation
#echo "yes" | rvm implode
