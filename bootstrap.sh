# The output of all these installation steps is noisy. With this utility
# the progress report is nice and concise.
function install {
    echo installing $1
    shift
    apt-get -y install "$@" >/dev/null 2>&1
}

echo adding swap file
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

echo updating system packages
apt-add-repository -y ppa:brightbox/ruby-ng >/dev/null 2>&1
apt-get -y update >/dev/null 2>&1

sudo apt-get -y install libssl-dev libsqlite3-dev gcc make python-pip dkms curl libxslt-dev libpq-dev python-dev python-pip python-feedvalidator software-properties-common python-sphinx libmariadb-client-lgpl-dev libcurl4-gnutls-dev libevent-dev libffi-dev stunnel4

install 'development tools' build-essential

#install Ruby ruby2.3 ruby2.3-dev

sudo apt-get -y install libssl1.0-dev autoconf bison libreadline-dev

su vagrant << EOF

  echo "Installing rbenv"
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  echo 'export PATH="\$HOME/.rbenv/bin:\$PATH"' >> ~/.bashrc
  echo 'eval "\$(rbenv init -)"' >> ~/.bashrc
  sudo ln -s /home/vagrant/.rbenv/bin/rbenv /usr/bin/rbenv
  source ~/.bashrc
  export PATH="$HOME/.rbenv/bin:$PATH
  eval "$(rbenv init -)"

  echo 'export PATH="\$HOME/.rbenv/plugins/ruby-build/bin:\$PATH"' >> ~/.bashrc
  source ~/.bashrc
  export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH

  echo Installing Ruby. NOTE: This may take some time.
  rbenv install 2.3.1
  rbenv local 2.3.1
  rbenv global 2.3.1

  echo installing Bundler
  sudo ln -s /home/vagrant/.rbenv/shims/gem /usr/bin/gem
  gem install bundler
  sudo ln -s /home/vagrant/.rbenv/shims/bundle /usr/bin/bundle

EOF

sudo apt-get -y install libssl-dev


#update-alternatives --set ruby /usr/bin/ruby2.3 >/dev/null 2>&1
#update-alternatives --set gem /usr/bin/gem2.3 >/dev/null 2>&1


# sudo apt-get update
# sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev

# cd
# git clone https://github.com/rbenv/rbenv.git ~/.rbenv
# echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
# echo 'eval "$(rbenv init -)"' >> ~/.bashrc
# exec $SHELL

# git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
# echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
# exec $SHELL

# rbenv install 2.3.1
# rbenv global 2.3.1
# ruby -v

install Git git

# Install MySQL
sudo apt-get -y install libaio1 libaio-dev

#debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
#debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
#install MySQL mysql-server libmysqlclient-dev
cd ~
wget https://cdn.mysql.com//Downloads/MySQL-5.5/mysql-5.5.60-linux-glibc2.12-x86_64.tar.gz
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
cd /usr/local
tar zxvf ~/mysql-5.5.60-linux-glibc2.12-x86_64.tar.gz
ln -s mysql-5.5.60-linux-glibc2.12-x86_64 mysql
ln -s /usr/local/mysql/bin/mysql /bin/mysql
cd mysql
chown -R mysql .
chgrp -R mysql .
scripts/mysql_install_db --user=mysql
chown -R root .
chown -R mysql data
cp support-files/my-medium.cnf /etc/my.cnf
bin/mysqld_safe --user=mysql &
cp support-files/mysql.server /etc/init.d/mysql.server
cd ~
rm mysql-5.5.60-linux-glibc2.12-x86_64.tar.gz

install 'Nokogiri dependencies' libxml2 libxml2-dev libxslt1-dev

echo Installing nodejs and npm
sudo apt-get -y purge nodejs
sudo apt-get -y purge npm
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get -y install nodejs
sudo apt-get -y install npm
sudo apt-get -y install uglifyjs
sudo ln -s "$(which nodejs)" /usr/local/bin/node
npm install -g jshint
npm install -g csslint
npm install -g jsonlint
npm install -g uglify-js
npm install -g bower


# Needed for docs generation.
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

# install hh tool
sudo apt-add-repository -y ppa:ultradvorka/ppa
sudo apt-get update
sudo apt-get install -y hh

sudo apt-get install -y libncurses5-dev libreadline-dev
wget https://github.com/dvorka/hstr/releases/download/1.10/hh-1.10-src.tgz
tar xf hh-1.10-src.tgz
cd hstr
./configure && make && sudo make install

hh --show-configuration >> ~/.bashrc
source ~/.bashrc

# install Java 8 and Ant
sudo apt-add-repository -y ppa:webupd8team/java
sudo apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get install -y oracle-java8-installer
sudo apt-get install -y ant

echo Creating MySQL databases

#mysql -uroot -proot <<SQL
mysql -uroot <<SQL
CREATE DATABASE codeworkout DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE opendsa DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

GRANT ALL PRIVILEGES ON codeworkout.* to 'codeworkout'@'localhost' IDENTIFIED BY 'codeworkout';
FLUSH PRIVILEGES;

GRANT ALL PRIVILEGES ON opendsa.* to 'opendsa'@'localhost'  IDENTIFIED BY 'opendsa';
FLUSH PRIVILEGES;
SET PASSWORD FOR root@localhost = PASSWORD('root');
SQL

# Clone code-workout
if [ ! -d /vagrant/code-workout ]; then
  git clone https://github.com/OpenDSA/code-workout.git /vagrant/code-workout
fi
git pull

cd /vagrant/code-workout
bundle install; bundle exec rake db:populate

# Clone OpenDSA
if [ ! -d /vagrant/OpenDSA ]; then
  git clone https://github.com/OpenDSA/OpenDSA.git /vagrant/OpenDSA
fi

# Checkout LTI_ruby branch
cd /vagrant/OpenDSA/
# git checkout LTI_ruby
make pull
cd /vagrant/OpenDSA/khan-exercises
# git checkout LTI_ruby
cd /vagrant/OpenDSA/
pip install -r requirements.txt --upgrade

# Clone OpenDSA-LTI
if [ ! -d /vagrant/OpenDSA-LTI ]; then
  git clone https://github.com/OpenDSA/OpenDSA-LTI.git /vagrant/OpenDSA-LTI
fi
git pull

cd /vagrant/OpenDSA-LTI
bundle install; bundle exec rake db:reset_populate

# Create link to OpenDSA
ln -s /vagrant/OpenDSA /vagrant/OpenDSA-LTI/public
ln -s /vagrant/OpenDSA/RST /vagrant/OpenDSA-LTI/RST
ln -s /vagrant/OpenDSA/config /vagrant/OpenDSA-LTI/Configuration
rm /vagrant/OpenDSA-LTI/Configuration/config
rm /vagrant/OpenDSA-LTI/RST/RST
sudo bower install --allow-root

echo 'all set, welcome to OpenDSA project!'
