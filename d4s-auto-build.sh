d4srepo="fosstp/drupal4school"
htmlroot="/var/www/html/"

cd /root/"$d4srepo"

check_remote=$(git pull origin)
check_time=$(date +"%Y%m%d_%T")

sed '28d' -i "$htmlroot"index.html
sed "28i  最近一次檢查時間LastCheck at <a href=log/checkanddeploy.log>$check_time</a></br>" -i "$htmlroot"index.html

if [[ "$(git pull origin)" == *"Already up-to-date."* ]]; then
	echo "$check_time   Already up-to-date,Do not need build!"
	echo "$check_time   Already up-to-date,Do not need build!" > "$htmlroot"log/checkanddeploy.log
	sed '29d' -i "$htmlroot"index.html
	sed "29i 測試網站 Running  <a href=http://163.21.204.168 target_blank>$(git reflog | awk 'NR==1{print $1}')</a>" -i "$htmlroot"index.html
else
	git_pull_reflog=$(git reflog --pretty='%cd %h' origin | awk 'NR==1{gsub(":",""); print "HEAD_"$7"_"$2"_"$3"_"$4"_"$5; }')
	echo $git_pull_reflog
	sed '29d' -i "$htmlroot"index.html
	sed "29i Start Building $git_pull_reflog....plz wait" -i "$htmlroot"index.html
	docker_build_tag=$(git reflog --pretty='%cd %h' origin | awk 'NR==1{ print $7; }')


	docker build -t "d4s-$docker_build_tag" /root/"$d4srepo" > "$htmlroot"log/"$git_pull_reflog.log"


	check_build=$(tail -n 1 "$htmlroot"log/"$git_pull_reflog.log")
	echo $check_build	

	if [[ "$check_build" == *"Successfully built"* ]]; then
		sed '29d' -i "$htmlroot"index.html
	        sed "29i $git_pull_reflog  Building Succesfull , now Deploy Drupal4School...wait again plz"  -i "$htmlroot"index.html

		
		imageid=$(tail -n 1 "$htmlroot"log/"$git_pull_reflog.log" | awk '{print $3}')
		echo "successfull....deployment d4s website"
		echo "</br>Git Repo "$git_pull_reflog" build  Successfull build time "$(date +"%Y%m%d_%T")" imageid="$imageid" <a href=log/$git_pull_reflog.log target=_blank>Buildlog</a>"  >> "$htmlroot"index.html
		docker stop $(docker ps -a -q)
		docker rm -f $(docker ps -a -q)
		docker pull mysql/mysql-server
		docker pull drupal:7
	
		docker run --restart=always  --name mysql -e MYSQL_ROOT_PASSWORD=1234 -e MYSQL_DATABASE=drupal  -d mysql/mysql-server
		printf "\nWaiting Mysql Container 3306 socket."

	        mysql_ip=$(docker inspect mysql|grep \"IPAddress\" | awk 'NR==1{gsub ( "\"","" );gsub ( "\,","" ); print $2 }')

                until nc -z -v -w30 $mysql_ip 3306 &> /dev/null
                do
                         printf "."
                        sleep 1
                done

                printf "Complete\n"


		
		docker run --restart=always  --name drupal --link mysql:db -p 80:80 -p 443:443 -d "d4s-$docker_build_tag"
		docker exec  drupal drush -y  site-install standard --clean-url=0 --site-name="$docker_build_tag" --account-pass=1234 --db-url=mysql://root:1234@db/drupal
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
		
		sed '29d' -i "$htmlroot"index.html
                sed "29i Deploy complete , now Running <a href=http://163.21.204.168 target=_blank>$git_pull_reflog</a>"  -i "$htmlroot"index.html
	fi
        if [[ "$check_build" != *"Successfully built"* ]]; then

	echo "</br>Git Head "$git_pull_reflog" build failed build time "$(date +"%Y%m%d_%T")" imageid=no-image <a href=log/$git_pull_reflog.log target=_blank>Buildlog</a>"  >> "$htmlroot"index.html
	fi

fi
