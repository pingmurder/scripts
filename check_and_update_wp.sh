#!/bin/bash
# 2015-11-27, asmo, v0.1
# 2015-12-05, fixes
# Check all directories recursively for valid WordPress instalations.
###

## config ##

     # provide path to wp-cli tool, default: /usr/local/bin/wpcli, don`t remove `--allow-root` option
wpt="/usr/local/bin/wpcli --allow-root"
f=$(which find)
     # oldest WordPress version supported by wp-cli
oldest_wp="3.5.2"
log_file="/root/.wpup_errors.txt"
## config ##

cau="0.2 - 05-12-2015"

function usage() {
	echo -e "This is version: ${cau}"
	echo -e "usage: $0 [top directory]\n\n\texample: $0 /home/wpuser/public_html"
	echo -e "\tor:\t $0 /home2/wpuser15/custom path with spaces\n"
	exit 0
}



function errors_check() {
        # check if wp-cli exists on specified path
        if [[ ! -x "/usr/local/bin/wpcli" ]]; then
                echo "error: wp-cli tool is missing, please install and/or set correct \$wpt variable, exiting."
                exit 1 ; fi

	# check for bash version
	bver=$(echo $BASH_VERSION|cut -d'.' -f1)
	if [[ ${bver} -lt 4 ]]; then
		echo "error: bash version 4.x required, exiting."
		exit 1 ; fi

	phpini=$(${wpt} --info|grep "ini used"|awk '{print $3}')
	phpdisfuncts=$(grep "^disable_functions =" ${phpini}|grep escapeshellarg|cut -d' ' -f3)
	if [[ ! -f "${phpini}" ]]; then
		echo "error: unable to locate php.ini via 'wpcli --info', please verify manually, exiting."
		exit 1
	  elif [[ ! -z "${phpdisfuncts}" ]]; then
		echo "error: required PHP function 'escapeshellarg()' is disabled in ${phpini}: ${phpdisfuncts}, needed by wp-cli to take WP DB backups, exiting."
		exit 1
	fi

	a_php=$(which php)
	if [[ -z ${a_php} ]]; then
		echo "error: unable to locate php, exiting."
		exit 1 ; fi

	# check if specified top directory exists
	if [[ ! -d "${topdir}" ]]; then
		echo "error: specified directory \"${topdir}\" does not exist, exiting."
		exit 1 ; fi

	# provide path to wp-cli tool, default: /usr/local/bin/wpcli
	wpt="/usr/local/bin/wpcli --allow-root"

	# check if wp-cli is working correctly; paranoid - check for `find` util too.
	${wpt} > /dev/null 2>&1 --info;isok=$?
	if [[ ! ${isok} -eq 0 ]] || [[ ! -x ${f} ]]; then
		echo "error: wp-cli and/or 'find' tool is not working correctly, please check manually, exiting."
		exit 1 ; fi
	echo -e "no errors, starting.\n"
}

# Generate list of directories to check, starting from directory passed to the script as an argument.
# If a directory contains WP instalation, all WP related subdirectories under that directory will be
# skipped, that is:
# `wp-admin`, `wp-content`, `wp-includes` and additionally `.htpasswds`.
# [[ && ]] && [[ ttt]]
# Then filter out the list and keep only directories with valid WP instalation
function scan_dirs() {
	echo "generating list of directories.. "
	# generate the list
	a_dirs=( $(${f} "${topdir}" \( -name wp-content -o -name wp-admin -o -name wp-includes -o -name .htpasswds \
		-o ! -type d \) -prune -o -print) )


	# adjust counter
	total_dirs=$((${#a_dirs[@]}-1))

	# quit if nothing is found
	if [[ ${total_dirs} -eq 0 ]]; then
		echo "no directories found, exiting"
		exit 1 ; fi

	echo -e "notice: found ${total_dirs} subdirectories under '${topdir}' top dir, scanning...\n"

	# switch to incremental
	d_init=0 ; dbg=1

	# use visual progress, might be handy for larger directory trees
	visualp=( '-' '\' '|' '/' '-'  '\' '|' '/' ) ; visualc=0
	# array for valid WP directories, force global
	valid_wp=( )

	# filtering, only directories with valid WP instalation will be counted
	while [[ ! ${d_init} -gt ${total_dirs} ]]; do

		# echo "debug: path = ${a_dirs[${d_init}]}"
		${wpt} > /dev/null 2>&1 --path="${a_dirs[${d_init}]}" core is-installed;iswp=$?

		if [[ ${iswp} -eq 0 ]]; then
			valid_wp+=( "${a_dirs[${d_init}]}" )
			echo -ne "\r\033[K\t\t\t WP(s) found: \033[1;31;40m[${#valid_wp[@]}]\033[0m - WP dir -> \"${a_dirs[${d_init}]}\" "
		fi

		   # calculate progress in percents
		   percent=$(echo|awk -v a_total=$total_dirs -v a_step=$d_init '{print (a_step/a_total)*100}'|awk '{printf("%.2f\n", $1)}')

		   # display progress
		   echo -ne "   \033[1;32;40m\r[${visualp[${visualc}]}] - ${percent}%\033[0m scanning:"
		   let visualc+=1 ; if [[ ${visualc} -gt 7 ]]; then visualc=0 ; fi


		let d_init+=1 ; let dbg+=1

	done

	echo -e "\ndone."
	#echo "debug: found ${#valid_wp[@]} valid WordPress instalations."
}


# Check and exclude WP versions older than 3.5, wp-cli doesn't support older releases.
function list_wp_versions() {
	d_init=0
	total_vdirs=$((${#valid_wp[@]}-1))

	#echo "debug: total_vdirs: ${total_vdirs}"

	a_pnum=( )
	a_tnum=( )
	# Make list of supported and unsupported WP versions
	while [[ ! ${d_init} -gt ${total_vdirs} ]]; do

		raw_chk_min_ver=$(${wpt} --path=${valid_wp[${d_init}]} core version);re=$?
		#echo "debug: wpt: raw_chk_min_ver: ${raw_chk_min_ver}, exec wpt: ${wpt} --path=${valid_wp[${d_init}]} core version"
		# mark valid dirs
		if [[ ${re} -eq 0 ]]; then

			# remove whitespaces, in some cases it's prefixed to the version string, breaking tests.
			chk_min_ver=$(echo "${raw_chk_min_ver}"|awk '{print $1}')
			# compare float variables via awk
			echo|awk -v a_minver="${oldest_wp}" -v a_curver="${chk_min_ver}" '{ if (a_curver<a_minver) exit 1 }';toold=$?
			#echo "debug0: toold: ${toold}, oldest_wp: ${oldest_wp}, chk_min_ver: ${chk_min_ver}"

			# perform compatible checks only within supported versions range for improved speed
			if [[ ${toold} -eq 0 ]]; then
				# check for new plugins and themes
				chk_old_plugin="$(${wpt} 2>/dev/null --path=${valid_wp[${d_init}]} plugin list)"
				chk_old_theme="$(${wpt} 2>/dev/null --path=${valid_wp[${d_init}]} theme list)"
				pnum="$(echo "${chk_old_plugin}"|grep available -c)"
				tnum="$(echo "${chk_old_theme}"|grep available -c)"
				a_pnum+=( "${pnum}" )
				a_tnum+=( "${tnum}" )
			  else
				# check and add unsupported versions
				unsported_vdirs+=( "${valid_wp[${d_init}]}" )
				echo -e "\033[1;31;40mCORE OVERWRITE QUEUED\033[0m [${d_init}] ancient core version: ${chk_min_ver} -> ${valid_wp[${d_init}]}"
			fi

			#echo "debug1: pnum/tnum: ${pnum} / ${tnum}, a_pnum/a_tnum: ${a_pnum[${d_init}]} / ${a_tnum[${d_init}]}"
			# echo "debug: in: list_wp_versions: pnum: ${pnum}, tnum: ${tnum}, a_pnum: ${a_pnum[@]}, a_tnum: ${a_tnum[@]}"

				# find and exclude directories where wp-cli failed to check plugin or theme list
				if [[ -z "${chk_old_plugin}" ]] || [[ -z "${chk_old_theme}" ]]; then
					echo -e "\033[1;31;40mfailed\033[0m :: ${valid_wp[${d_init}]} :: core version: ${chk_min_ver} unable to list plugins / themes, excluded, please check manually."
				  else
					if [[ ${pnum} -eq 0 ]] && [[ ${tnum} -eq 0 ]]; then
						if [[ "${chk_min_ver}" = "${latest_wp}" ]]; then
							uptodate+=( "${valid_wp[${d_init}]}" )
							echo -e "   \033[1;32;40mALREADY UP TO DATE\033[0m [${d_init}] core version: ${chk_min_ver} -> ${valid_wp[${d_init}]}"
						fi
					  else
						#echo -e "WP at: ${valid_wp[${d_init}]} - core version: ${chk_min_ver}, new plugins/themes: [${pnum}/${tnum} - \033[1;33;40mUPDATE QUEUED\033[0m"
						supported_vdirs+=( "${valid_wp[${d_init}]}" )
						echo -e "        \033[1;33;40mUPDATE QUEUED\033[0m [${d_init}] core version: ${chk_min_ver}, new plugins/themes: ${pnum}/${tnum} -> ${valid_wp[${d_init}]}"
						
					fi
				fi

		fi
			
	  let d_init+=1
	done

	queued_old="${#unsported_vdirs[@]}"
	queued="${#supported_vdirs[@]}"
	echo -e  "\nWP instances summary:\n....................."
	echo -e "queued for update:  ${#supported_vdirs[@]}\nancient (<${oldest_wp}): ${#unsported_vdirs[@]} \
		\n\ralready up to date: ${#uptodate[@]}\n.....................\n"
}

# update ancient WP
function force_update_old() {
	d_init=0 ; cnt_now=1
	total_old=$((${#unsported_vdirs[@]}-1)) ; cnt_max=${#unsported_vdirs[@]}

	while [[ ! ${d_init} -gt ${total_old} ]]; do

		echo -ne "[\033[1;32;40m${cnt_now}\033[0m/\033[;1;32;40m${cnt_max}\033[0m] - "
		echo -n "force core download on < ${oldest_wp}.. "
		${wpt} >/dev/null 2>&1 --path="${unsported_vdirs[${d_init}]}" --force core download
		echo -n "attempting plugin(s) update.. "
		${wpt} >/dev/null 2>&1 --path="${unsported_vdirs[${d_init}]}" plugin update --all
		echo -n "attempting theme(s) update.. "
		${wpt} >/dev/null 2>&1 --path="${unsported_vdirs[${d_init}]}" theme update --all
		echo "done"
	    let d_init+=1 ; let cnt_now+=1

	done
}


# Update outdated WP instances, exclude unsupported and latest versions.
function update_qualified() {

	d_init=0 ; cnt_now=1
	total_valid=$((${#supported_vdirs[@]}-1)) ; cnt_max=${#supported_vdirs[@]}

	while [[ ! ${d_init} -gt ${total_valid} ]]; do

		echo -ne "[\033[1;32;40m${cnt_now}\033[0m/\033[;1;32;40m${cnt_max}\033[0m] - ${supported_vdirs[${d_init}]} - "
		# take backup if requested
		if [[ "${rb}" = "backup" ]]; then
			
			if [[ "${supported_vdirs[${d_init}]}" = "${topdir}" ]]; then
				echo "notice: skipping backup of ${topdir}"
			  else
				echo -en "creating DB backup.. "
				bckp_name="$(basename ${supported_vdirs[${d_init}]})"
				${wpt} >/dev/null 2>&1 --path="${supported_vdirs[${d_init}]}" db export "${supported_vdirs[${d_init}]}"/../"${bckp_name}.sql"

				if [[ ! -f "${supported_vdirs[${d_init}]}/../${bckp_name}.sql" ]]; then
					echo "fatal: db backup failed"
					exit 1
				fi
				echo -n "dir backup.. "
				tar -cPf "${supported_vdirs[${d_init}]}"/../"${bckp_name}".tar "${supported_vdirs[${d_init}]}"
				if [[ ! -f "${supported_vdirs[${d_init}]}/../${bckp_name}.tar" ]]; then
					echo "fatal: ${supported_vdirs[${d_init}]}/../${bckp_name}.tar backup not found, exiting."
					exit 1
				fi
			fi
		fi

		#echo "debug in update_qualified: a_pnum[d_init]: ${a_pnum[${d_init}]}, a_tnum[d_init] ${a_tnum[${d_init}]}"
		## start updating core, plugins, themes
		#
		# update WP core, themes or plugins only if needed to improve general perfomance
		if [[ ! "${latest_wp}" = "${chk_min_ver}" ]]; then
			echo -n "updating: core . "
			${wpt} >/dev/null 2>&1 --path="${supported_vdirs[${d_init}]}" core update
			echo -n "db.. "
			${wpt} >/dev/null 2>&1 --path="${supported_vdirs[${d_init}]}" core update-db
		fi
		#echo "debug: in: update_qualified: chk_old_plugin: ${chk_old_plugin}, chk_old_theme: ${chk_old_theme}, pnum: ${pnum}, tnum: ${tnum}, a_pnum: ${pnum[${d_init}]}, a_tnum: ${tnum[${d_init}]}"
		roll_back=0


			## Plugins update
			##
		echo -n "plugin(s).. "
		${wpt} 1>/dev/null 2>>${log_file} --path="${supported_vdirs[${d_init}]}" plugin update --all;plugin_ok=$?
		if [[ ! ${plugin_ok} -eq 0 ]] && [[ "${rb}" = "backup" ]]; then
			echo "WP dir: ${supported_vdirs[${d_init}]} - one or more plugins failed to update, wrote to ${log_file}"
			echo -e "\n\t${supported_vdirs[${d_init}]} one or more plugins failed to update." >>${log_file}
			#roll_back=1
		fi

		## Themes update
		# continue with theme updates only if plugin update succeed
		echo -n "theme(s).. "
		${wpt} 1>/dev/null 2>>${log_file} --path="${supported_vdirs[${d_init}]}" theme update --all;theme_ok=$?
		let cnt_tnow+=1
		if [[ ! ${theme_ok} -eq 0 ]] && [[ "${rb}" = "backup" ]]; then
			echo "WP dir: ${supported_vdirs[${d_init}]} - one or more themes failed to update, wrote to ${log_file}"
			echo -e "\n\t${supported_vdirs[${d_init}]} one or more themes update failed to update." >>${log_file}
		fi
			
		echo -n "dirty checks.. "
		${a_php} "${supported_vdirs[${d_init}]}/index.php" > /tmp/.tmp_chkwpindex
		is_fail1=$(grep 'Database Error' /tmp/.tmp_chkwpindex|wc -l)
		is_fail2=$(grep -i html /tmp/.tmp_chkwpindex|wc -l)
		is_fail3=$(cat /tmp/.tmp_chkwpindex|wc -l)


		if [[ ${if_fail1} -gt 0 ]]; then
			echo "failed - Database Error found"
			update_failed=1 
		  elif [[ ${is_fail2} -eq 0 ]]; then
			echo "failed - no html tags found via 'php index.php'"
			update_failed=1
		  elif [[ ${is_fail3} -lt 20 ]]; then
			echo "failed - 'php index.php' output is less than 20, assuming broken WP"
			update_failed=1
		fi
		 
			update_failed=0

		if [[ ${update_failed} -eq 1 ]] && [[ "${rb}" = "backup" ]]; then
		
			echo -ne "\t\033[1;31;40mfailed\033[0m - restoring.. "

			if [[ -f "${supported_vdirs[${d_init}]}/../${bckp_name}.tar" ]] && [[ -f "${supported_vdirs[${d_init}]}/../${bckp_name}.sql" ]]; then
				mv "${supported_vdirs[${d_init}]}"/../"${bckp_name}" "${supported_vdirs[${d_init}]}"/../"_wp_updatefailed___${bckp_name}"				

				tar -xPf "${supported_vdirs[${d_init}]}".tar;s=$?
				if [[ ${s} -eq 0 ]]; then
					rm -rf "${supported_vdirs[${d_init}]}"/../"_wp_updatefailed___${bckp_name}" /tmp/.tmp_chkwpindex
					echo -n "DB.. "
					${wpt} >/dev/null 2>&1 --path="${supported_vdirs[${d_init}]}" db import "${supported_vdirs[${d_init}]}"/../"${bckp_name}.sql";y=$?
					if [[ ${y} -eq 0 ]]; then
						rm -f "${supported_vdirs[${d_init}]}"/../"${bckp_name}.tar" "${supported_vdirs[${d_init}]}"/../"${bckp_name}.sql"
					fi
				  else
					echo "fatal: failed to make .tar on ${supported_vdirs[${d_init}]}, exiting."
					exit 1
				fi
			fi

			echo -ne "\033[1;33;40mrestored\033[0m.\n"
		  else
			echo -e "\033[1;32;40mupdated\033[0m."
			rm -f "${supported_vdirs[${d_init}]}"/../"${bckp_name}.tar" "${supported_vdirs[${d_init}]}"/../"${bckp_name}.sql"
		fi
			
	   let d_init+=1 ; let cnt_now+=1
	done
}


##
## main
##

topdir="$@"

if [[ -z "${topdir}" ]]; then
	usage
 else 	errors_check ; fi

# wipe logfile
> ${log_file}

wget -q -O /tmp/.wpver --no-check-certificate https://api.wordpress.org/core/version-check/1.6/ || \
	( echo "error: unable to download WP version string from api.wordpress.org" && echo exit 1 )
latest_wp=$(awk -F"wordpress-" '{print $2}' /tmp/.wpver|awk -F".zip" '{print $1}';rm -f /tmp/.wpver)


scan_dirs

list_wp_versions

if [[ ${queued_old} -gt 0 ]]; then
	# Require confirmation before starting updates.
	echo -n "Please confirm ancient WP core, plugins and themes update by typing 'yes': ";read;r=${REPLY}
	if [[ ${r} = "yes" ]]; then
		force_update_old
	fi
fi

# update WP-CLI supported WP versions
if [[ ${queued} -gt 0 ]]; then
	# Require confirmation before starting updates.
	echo -en "\nPlease confirm WP core, plugins and themes update by typing 'yes': ";read;r=${REPLY}
		if [[ "${r}" = "yes" ]]; then

			# require backup or nobackup option
			while [[ ! "${rb}" = "backup" ]] && [[ ! "${rb}" = "nobackup" ]]; do
				echo -n "Please type 'backup' for safe update, otherwise 'nobackup': ";read;rb=${REPLY}

				if [[ "${rb}" = "backup" ]]; then
					echo "notice: updating with backup."
					update_qualified
					echo "errors stored in ${log_file} (if any)"
				  elif [[ "${rb}" = "nobackup" ]]; then
						echo "notice: updating without backup."
						update_qualified
						echo "errors stored in ${log_file} (if any)"
				  else
						echo "'backup' or 'nobackup' required."
				fi
			done

		  else
				echo "exiting." ; exit 1
		fi
  else
	echo "nothing to update, exiting."
	exit 0
fi
