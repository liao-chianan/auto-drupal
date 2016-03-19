echo -e "於debian系統底下 安裝docker\n\n"
apt-get update && apt-get -y install curl  && curl -fsSL https://get.docker.com/ | sh


echo -e "開始進行參數設定\n\n"
read -p "請輸入您要使用的mysql root密碼(Please enter your mysql root password for setting up): " mysql_pw

read -p "請輸入您要使用的drupal站台名稱(Please enter your drupal site-name): "  drupal_sitename

read -p "請輸入您要使用的drupal管理員密碼(Please enter your drupal admin password): "  drupal_admin_pw


echo  -n "開始進行mysql docker部署動作...."

docker run --name mysql -e MYSQL_ROOT_PASSWORD=$mysql_pw -e MYSQL_DATABASE=drupal  -d mysql/mysql-server
docker run --name mysqlwait --link mysql aanand/wait
docker rm mysqlwait

echo -n "開始進行drupal docker部署動作...."

docker run --name drupal --link mysql:db -p 80:80 -p 443:443 -d fosstp/drupal


echo -n "開始進行 drupal 站台自動化安裝作業"

docker exec  drupal drush -y  site-install standard --clean-url=0 --site-name=$drupal_sitename --account-pass=$drupal_admin_pw --db-url=mysql://root:${mysql_pw}@db/drupal

echo -n "開始進行 drupal 中文化介面與校務模組安裝"

docker exec  drupal drush dl drush_language
docker exec  drupal drush dl l10n_update && drush en -y $_
docker exec  drupal curl -O https://ftp.drupal.org/files/translations/7.x/drupal/drupal-7.x.zh-hant.po
docker exec  drupal drush language-import zh-hant drupal-7.x.zh-hant.po
docker exec  drupal drush -y en locale translation views date calendar
docker exec  drupal drush -y en openid_provider simsauth sims_views sims_field gapps db2health openid_moe adsync  gevent thumbnail_link   xrds_simple
docker exec  drupal drush language-add zh-hant && drush language-enable zh-hant && drush language-default zh-hant
echo -n "安裝結束 您可以使用下列網址測試drupal是否安裝成功 系統管理員帳號為admin 密碼為"$drupal_admin_pw
ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print "http://"$1"/"}'
