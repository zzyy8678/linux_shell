#!/bin/bash

Project=$2
ImageItem=$3
ChangeImage=$4
ChangeVersion=$5
TheSameImage=$6
BmcImagePath=$4
DiagImagePath=$4
CitImagePath=$4
CommonSwImageYaml="SwImagesFormal.yaml"
SwImageYaml="SwImages.yaml"
ToolPath="/home/cap/docker-compose-script/tools/"
MP2Path="/home/cap/docker-compose-script/"
W400Path="/home/cap/docker-compose-script/wedge400/"
ChangeImageUnit="/home/cap/docker-compose-script/tools/imageUnit.txt"
CLS_Main_BMC_Path="BMC"
Meta_Main_BMC_Path="MetaBMC"
AutoBuildTrue="true"
AutoBuildFalse="false"
Mp2BmcFormal="BmcFormal"
W400BmcFormal="OpenBMC"
Mp2DiagFormal="DiagFormal"
DiagDaily="DIAG"
CIT_CLS_Main="daily"
CIT_Meta_Main="Metadaily"
num=1

function change_path()
{
    echo -e "=============== change the \e[1;31m$Project ${ImageItem}\e[0m SwImage info ================="
		if [ "$Project" == "w400c" ] || [ "$Project" == "mp2" ];then
			cd $MP2Path
		elif [ "$Project" == "w400" ];then
			cd $W400Path
		fi 
}

#For BMC, DIAG daily build image and CIT folder change
function run_auto_build_image()
{
	change_path
	while read line
	do
		echo -e "\e[1;32m###### The step change the $line auto build image. ######\e[0m"
		cd $line
		hostImageDir=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'hostImageDir' |awk -F"/" '{print $NF}' |awk '{print $1}'`
        isAutoBuild=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'isAutoBuild' |awk -F":" '{print $2}' |awk '{print $1}'`
		#BMC daily line
		for k in ${CLS_Main_BMC_Path} ${Meta_Main_BMC_Path} ${Mp2BmcFormal} ${W400BmcFormal}
		do
			BMCFolder=`cat ${SwImageYaml} |grep -wn "autotest/$k" |awk -F: '{print $1}'`
			if [ -z $BMCFolder ];then
				continue
			else
				BMCFolderLine=$BMCFolder
				NextLine=$(expr $BMCFolder + $num)
			fi 
		done
		#DIAG daily line
		for i in ${Mp2DiagFormal} ${DiagDaily}
		do
			DIAGFolder=`cat ${SwImageYaml} |grep -wn "autotest/$i" |awk -F: '{print $1}'`
			if [ -z $DIAGFolder ];then
				continue
			else
				DIAGFolderLine=$DIAGFolder
				DiagNextLine=$(expr $DIAGFolder + $num)
			fi 
		done
		
		#BMC daily 
		if [ "${ImageItem}" == "BMC" ];then
			#1. For Meta_Mian, change the image path and isAuto to true
			if [ "${BmcImagePath}" == "MetaBMC" ];then
				if [ "$hostImageDir" == "MetaBMC" ] && [ "$isAutoBuild" == "true" ];then
					cd - >/dev/null
					continue
				fi
				sed -i "${BMCFolderLine}s/${hostImageDir}/${Meta_Main_BMC_Path}/" $SwImageYaml
				sed -i "${NextLine}s/${isAutoBuild}/${AutoBuildTrue}/" $SwImageYaml
			#2. For CLS_Main image
			elif [ "${BmcImagePath}" == "BMC" ];then
				if [ "$hostImageDir" == "BMC" ] && [ "$isAutoBuild" == "true" ];then
					cd - >/dev/null
                    continue
                fi
				sed -i "${BMCFolderLine}s/${hostImageDir}/${CLS_Main_BMC_Path}/" $SwImageYaml
				sed -i "${NextLine}s/${isAutoBuild}/${AutoBuildTrue}/" $SwImageYaml
			#3. For formal image
			elif [ "${BmcImagePath}" == "OpenBMC" ] || [ "${BmcImagePath}" == "BmcFormal" ];then
				if [ "$Project" == "mp2" ];then
					sed -i "${BMCFolderLine}s/${hostImageDir}/${Mp2BmcFormal}/" $SwImageYaml
					sed -i "${NextLine}s/${isAutoBuild}/${AutoBuildFalse}/" $SwImageYaml
				else
					sed -i "${BMCFolderLine}s/${hostImageDir}/${W400BmcFormal}/" $SwImageYaml
                    sed -i "${NextLine}s/${isAutoBuild}/${AutoBuildFalse}/" $SwImageYaml
                fi
			fi		
		fi
		
		#DIAG daily
		if [ "${ImageItem}" == "DIAG" ];then
			#1. For DIAG daily image
			if [ "${DiagImagePath}" == "DIAG" ];then
				if [ "$hostImageDir" == "DIAG" ] && [ "$isAutoBuild" == "true" ];then
					cd - >/dev/null
					continue
				fi
				sed -i "${DIAGFolderLine}s/${hostImageDir}/${DiagDaily}/" $SwImageYaml
				sed -i "${DiagNextLine}s/${isAutoBuild}/${AutoBuildTrue}/" $SwImageYaml
			#2. For DIAG Formal image
			elif [ "${DiagImagePath}" == "DiagFormal" ];then
				if [ "$hostImageDir" == "DiagFormal" ] && [ "$isAutoBuild" == "false" ];then
					cd - >/dev/null
					continue
				fi
				sed -i "${DIAGFolderLine}s/${hostImageDir}/${Mp2DiagFormal}/" $SwImageYaml
				sed -i "${DiagNextLine}s/${isAutoBuild}/${AutoBuildFalse}/" $SwImageYaml
			fi
		fi
		
		#CIT folder change
		if [ "${ImageItem}" == "CIT" ];then
			CitFolderLine=`cat ${SwImageYaml} |grep -wn "autotest/CIT" |awk -F: '{print $1}'`
			#1. For formal cit
			if [ "${hostImageDir}" == "CIT" ];then
				if [ "${CitImagePath}" == "daily" ] || [ "${CitImagePath}" == "Metadaily" ];then
					sed -i "${CitFolderLine}s/$/&\/${CitImagePath}/" $SwImageYaml
				elif [ "${CitImagePath}" == "CIT" ];then
					cd - >/dev/null
					continue
				fi
			#2. For CLS_Main cit
			elif [ "${hostImageDir}" == "daily" ];then
				if [ "${CitImagePath}" == "Metadaily" ];then
					sed -i "${CitFolderLine}s/${hostImageDir}/${CitImagePath}/" $SwImageYaml
				elif [ "${CitImagePath}" == "CIT" ];then
					sed -i "${CitFolderLine}s/\/${hostImageDir}//" $SwImageYaml
				elif [ "${CitImagePath}" == "daily" ];then
					cd - >/dev/null
					continue
				fi
			#3. For Meta_Main cit
			elif [ "${hostImageDir}" == "Metadaily" ];then
				if [ "${CitImagePath}" == "daily" ];then
					sed -i "${CitFolderLine}s/${hostImageDir}/${CitImagePath}/" $SwImageYaml
				elif [ "${CitImagePath}" == "CIT" ];then
					sed -i "${CitFolderLine}s/\/${hostImageDir}//" $SwImageYaml
				elif [ "${CitImagePath}" == "Metadaily" ];then
					cd - >/dev/null
					continue
				fi
			fi
		fi
		
		cd - >/dev/null
	done < $ChangeImageUnit
	cd - >/dev/null		
}


#for BMC, BIOS, BIC, TPM, DIAG  
function run_formal_image()
{
	change_path
    while read line
    do
        echo -e "\e[1;32m###### The step change the $line formal image. ######\e[0m"
		cd $line
        oldImage=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldImage' |awk -F"'" '{print $2}'`
        newImage=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newImage' |awk -F"'" '{print $2}'`
        oldVersion=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldVersion' |awk -F"'" '{print $2}'`
        newVersion=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newVersion' |awk -F"'" '{print $2}'`
		hostImageDir=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'hostImageDir' |awk -F"/" '{print $NF}' |awk '{print $1}'`
        isAutoBuild=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'isAutoBuild' |awk -F":" '{print $2}' |awk '{print $1}'`
		#get the line number
		oldImageLine=`cat ${SwImageYaml} |grep -wnA11 "${ImageItem}:" |grep 'oldImage' |awk -F"-" '{print $1}'`
        newImageLine=`cat ${SwImageYaml} |grep -wnA11 "${ImageItem}:" |grep 'newImage' |awk -F"-" '{print $1}'`
		oldVerLine=`cat ${SwImageYaml} |grep -wnA11 "${ImageItem}:" |grep 'oldVersion' |awk -F"-" '{print $1}'`
		newVerLine=`cat ${SwImageYaml} |grep -wnA11 "${ImageItem}:" |grep 'newVersion' |awk -F"-" '{print $1}'`
		if [ "$TheSameImage" == "only" ];then
			sed -i "${oldImageLine}s/${oldImage}/${ChangeImage}/" $SwImageYaml
			sed -i "${oldVerLine}s/${oldVersion}/${ChangeVersion}/" $SwImageYaml
			sed -i "${newImageLine}s/${newImage}/${ChangeImage}/" $SwImageYaml
			sed -i "${newVerLine}s/${newVersion}/${ChangeVersion}/" $SwImageYaml
		else
			if [ "${newVersion}" == "${ChangeVersion}" ];then
				cd - >/dev/null
				continue
			fi
            sed -i "${newImageLine}s/${newImage}/${ChangeImage}/" $SwImageYaml
            sed -i "${newVerLine}s/${newVersion}/${ChangeVersion}/" $SwImageYaml
            sed -i "${oldImageLine}s/${oldImage}/${newImage}/" $SwImageYaml
            sed -i "${oldVerLine}s/${oldVersion}/${newVersion}/" $SwImageYaml
		fi
		
		#CPLD image
		if [ "${ImageItem}" == "CPLD" ];then
			if [ "$Project" == "mp2" ];then
				#1. CPLD image and line
				for i in "fcm" "scm" "smb" "pwr"
				do
					"old"${i}"Image"=`cat ${SwImageYaml} |grep -wnA11 "CPLD:" |grep "$i" |awk -F"'" '{print $2}'`
					"old"${i}"ImageLine"=`cat ${SwImageYaml} |grep -wnA11 "CPLD:" |grep "$i" |awk -F"-" '{print $1}'`
					"new"${i}"Image"=`cat ${SwImageYaml} |grep -wnA16 "CPLD:" |grep -A5 "newImage" |grep "$i" |awk -F"'" '{print $2}'`
					"new"${i}"ImageLine"=`cat ${SwImageYaml} |grep -wnA16 "CPLD:" |grep -A5 "newImage" |grep "$i" |awk -F"-" '{print $1}'`
				
				done
				#2. CPLD version and line
				
			fi
	
			if [ "$Project" == "w400" ] || [ "$Project" == "w400c" ];then
				if [ "${hostImageDir}" == "${W400BmcFormal}" ];then
	                continue
                else
                    sed -i "0,/${hostImageDir}/s//${W400BmcFormal}/" $SwImageYaml
					sed -i "0,/${isAutoBuild}/s//${AutoBUildFalse}/" $SwImageYaml
                fi
			fi
		fi
        cd - >/dev/null
    done < $ChangeImageUnit
    cd - >/dev/null
}


function run_common_image()
{
	echo "=============== change the common SwImage info ================="
	cd ../$ProjectPath/common
	bmc_oldImage=`cat ${CommonSwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldImage' |awk -F"'" '{print $2}'`
	bmc_newImage=`cat ${CommonSwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newImage' |awk -F"'" '{print $2}'`
	bmc_oldVersion=`cat ${CommonSwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldVersion' |awk -F"'" '{print $2}'`
	bmc_newVersion=`cat ${CommonSwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newVersion' |awk -F"'" '{print $2}'`
	sed -i "s/${bmc_oldImage}/${bmc_newImage}/" $CommonSwImageYaml
	sed -i "s/${bmc_oldVersion}/${bmc_newVersion}/" $CommonSwImageYaml
	sed -i "s/${bmc_newImage}/${FormalImage}/" $CommonSwImageYaml
	sed -i "s/${bmc_newVersion}/${FormalVersion}/" $CommonSwImageYaml
	cd -
}

function run_w400c_image()
{
	echo "=============== change the w400c SwImage info ================="
	cd ../
	while read line
	do
		cd $line
		bmc_oldImage=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldImage' |awk -F"'" '{print $2}'`
		bmc_newImage=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newImage' |awk -F"'" '{print $2}'`
		bmc_oldVersion=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldVersion' |awk -F"'" '{print $2}'`
		bmc_newVersion=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newVersion' |awk -F"'" '{print $2}'`
		if [[ -z "${bmc_oldImage}" ]];then
			bmc_oldImage=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldImage' |awk -F":" '{print $2}'`
			bmc_newImage=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newImage' |awk -F":" '{print $2}'`
			bmc_oldVersion=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'oldVersion' |awk -F":" '{print $2}'`
			bmc_newVersion=`cat ${SwImageYaml} |grep -A11 "${ImageItem}:" |grep 'newVersion' |awk -F":" '{print $2}'`
			echo "111111111111111111111111"
			echo ${FormalVersion}
			echo "2222222222222222222222222"
			#sed -i "s/${bmc_oldImage}/ '${FormalImage}'/" $SwImageYaml
			sed -i "s/${bmc_oldVersion}/ '${FormalVersion}'/" $SwImageYaml
			#sed -i "s/${bmc_newImage}/ '${FormalImage}'/" $SwImageYaml
			sed -i "s/${bmc_newVersion}/ '${FormalVersion}'/" $SwImageYaml
		else
			sed -i "s/${bmc_oldImage}/${bmc_newImage}/" $SwImageYaml
			sed -i "s/${bmc_oldVersion}/${bmc_newVersion}/" $SwImageYaml
			sed -i "s/${bmc_newImage}/${FormalImage}/" $SwImageYaml
			sed -i "s/${bmc_newVersion}/${FormalVersion}/" $SwImageYaml
		fi
		cd ../
	done < tools/w400c_unit.txt
	cd -
}

function usage()
{
    echo "    -h  show help"
    echo -e "    \e[1;31m==== First pls edit the imageUnit.txt file for needing to change the unit ====\e[0m"
    echo -e "    \e[1;32mFor project: w400, w400c, mp2.\e[0m"
    echo -e "    \e[1;32mFor ImageItem: BMC, diag, SDK, BIOS, CIT ......\e[0m"
    echo -e "    \e[1;32m-t bmc,diag type, for exapmle: formal or daily.\e[0m"
    echo -e "    \e[1;32m-c modify the common uint image.\e[0m"
    echo -e "    \e[1;32m-m modify formal image unit. if need the same image file, add the 'only' keyword at last.\e[0m"
    echo -e "    \e[1;31m	./change_image.sh -m project ImageItem NewImage NewVersion [only]\e[0m"
    echo -e "    \e[1;32m-a modify auto build image unit, for BMC, DIAG image.\e[0m"
    echo -e "    \e[1;31m	./change_image.sh -a project ImageItem ImageFolder [true|false]\e[0m"
    #echo -e "    \e[1;31m./change_tag.sh -a project case all_tag\e[0m"
}

if [ $# -lt 1 ];then
        echo "argument is so few, please see the below command:"
        usage
        exit

fi

while getopts "hpmacFt" arg
do
  case $arg in
        h)
                operation="help"
                ;;

        p)
                operation="project"
                ;;
        m)
                operation="image"
                ;;

        a)
                operation="auto"
                ;;
        c)
                operation="common"
                ;;
        F)
                operation=modify
                ;;
        t)
                operation="type"
                ;;
        ?)
                echo "unknown argument"
                usage
                exit 1
                ;;
  esac
done

if [ "$operation" == "help" ];then
    usage
elif [ "$operation" == "common" ];then
        if [ "${Project}" == "w400" ];then
            run_common_image
        elif [ "${Project}" == "w400c" ];then
            run_common_image
        fi
elif [ "$operation" == "image" ];then
        if [ "${Project}" == "w400" ];then
            run_formal_image
	elif [ "${Project}" == "w400c" ];then
            run_formal_image
	elif [ "${Project}" == "mp2" ];then
            run_formal_image
        fi
elif [ "$operation" == "auto" ];then
        if [ "${Project}" == "mp2" ];then
            run_auto_build_image
	elif [ "${Project}" == "w400" ];then
            run_auto_build_image
	elif [ "${Project}" == "w400c" ];then
            run_auto_build_image
        fi
fi


