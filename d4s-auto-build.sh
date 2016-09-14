mkdir ~/drupal4school
cd ~/drupal4school
git clone https://github.com/liao-chianan/drupal4school
cd ~/drupal4school

check_remote=$(git pull origin)
check_time=$(date +"%Y%m%d_%T")
if [[ "$check_remote" == "Already up-to-date." ]]; then
	echo "$check_time   Already up-to-date,Do not need build!"
else
	git_pull_reflog=$(git reflog --date=iso  master | awk 'NR==1{gsub ( "master@{","master_" ) ; print $1"_"$2"_"$3; }')
	echo $git_pull_reflog

	docker_build_tag=$(git reflog --date=iso  master | awk 'NR==1{gsub ( "master@{","master_" ) ; print $1 }')
	docker build -t "d4s-$docker_build_tag" ~/drupal4school > ~/"$git_pull_reflog.log"


	check_build=$(tail -n 1 ~/"$git_pull_reflog.log")
	

	if [[ "$check_build" == *"Successfully built"* ]]; then
		echo "successfull....deployment d4s website"
		imageid=$(tail -n 1 ~/"$git_pull_reflog.log" | awk '{print $3}')
		docker stop $(docker ps -a -q)
		docker rm -f $(docker ps -a -q)
		docker rmi -f $(docker images -q| awk '$0 != "'"$imageid"'" {print}') 
	
		docker run --restart=always  --name mysql -e MYSQL_ROOT_PASSWORD=1234 -e MYSQL_DATABASE=drupal  -d mysql/mysql-server
		printf "\nWaiting Mysql Container Loading."
		until [ $(docker inspect mysql|grep \"Pid\" | awk '{print  $2}'|sed -r "s/[,]+//g") -ne "0" ]; do
		        printf "."
		        sleep 1
		done
		printf "Complete\n"

		
		docker run --restart=always  --name drupal --link mysql:db -p 80:80 -p 443:443 -d "d4s-$docker_build_tag"
		docker exec  drupal drush -y  site-install standard --clean-url=0 --site-name=$docker_build_tag --account-pass=1234 --db-url=mysql://root:1234@db/drupal
		docker exec  drupal cp /etc/php5/cli/php.ini  /usr/local/etc/php/
		docker exec  drupal sed -i 's/memory_limit = -1/memory_limit = 256M/g' /usr/local/etc/php/php.ini
		docker exec  drupal drush dl drush_language -y
		docker exec  drupal drush dl l10n_update -y
		docker exec  drupal drush en -y l10n_update
		docker exec  drupal drush language-add zh-hant 
		docker exec  drupal drush language-enable zh-hant 
		docker exec  drupal drush language-default zh-hant
		docker exec  drupal curl -O https://ftp.drupal.org/files/translations/7.x/drupal/drupal-7.x.zh-hant.po
		docker exec  drupal drush language-import zh-hant drupal-7.x.zh-hant.po
		docker exec  drupal drush -y en locale translation views date calendar
		docker exec  drupal drush -y en openid_provider simsauth sims_views sims_field gapps db2health openid_moe adsync  gevent thumbnail_link   xrds_simple
		docker exec  drupal chown -R www-data:www-data /var/www/html/sites/default
		docker exec  drupal chmod -R 755 /var/www/html/sites/default/files
		docker restart drupal
	fi
	

fi

