#!/bin/bash
PID=$$
NO_ARGS=0
E_OPTERROR=85
PROJECT_NAME=""
VERSION_NAME=""
ENV_NAME=""
TARGET=$HOME".bvrconfig/archive"
CONFIG_LOCATION=$HOME"./bvrconfig"
SERVER_DEPLOY_TMP_HOME="/tmp/$PID"
OVERWRITE=false
ENV_NAME_CONFIG=""

if [ $# -eq "$NO_ARGS" ]    # Script invoked with no command-line args?
then
  echo "Usage: `basename $0` options (-pv)"
  exit $E_OPTERROR          # Exit and explain usage.
                            # Usage: scriptname -options
                            # Note: dash (-) necessary
fi
while getopts ":tp:v:e:c:R:" Option
do
	case $Option in
		t	) echo $TARGET; exit;;
		p	) echo "-Project: ${OPTARG}"; PROJECT_NAME=${OPTARG};;
		c   ) echo "-Config Dir:${OPTARG}"; CONFIG_LOCATION=${OPTARG};;
		v	) echo "-Version ${OPTARG}"; VERSION_NAME=${OPTARG};;
		e	) echo "-Enviorment ${OPTARG}"; ENV_NAME=${OPTARG}; ENV_NAME_CONFIG=${OPTARG};;
		R	) echo "-Overwrite destination package"; OVERWRITE=${OPTARG};;
	esac
done

FILE=$TARGET/$PROJECT_NAME/$VERSION_NAME/package.tgz;

if [ ! -e $FILE ]
then 
	echo "Could not find archive: $FILE";
	exit $E_OPTERROR;
else
	echo "File Found !";
fi

CONFIG=$CONFIG_LOCATION/$PROJECT_NAME/$ENV_NAME/servers

if [ ! -e $CONFIG ]
then 
	echo "Could not find enviorment: $CONFIG";
	exit $E_OPTERROR;
else
	echo "Config Found !"
fi

source $CONFIG;

#echo $TEST1;

REMOTE_PATH=$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/$VERSION_NAME

REMOTE_TMP_PATH="$SERVER_DEPLOY_HOME/$PROJECT_NAME/$ENV_NAME/tmp_${PID}_$VERSION_NAME/"

for DEST in "${SERVERS[@]}"
do
	echo "-- Trying to deploy to: $DEST"
	EXIST=`ssh $DEST test -d $REMOTE_PATH || echo "NA"`;
	if [ "$EXIST" = "NA" -o "$OVERWRITE"="true"  ] ; then		
		ssh $DEST mkdir -p $REMOTE_TMP_PATH
		scp $FILE $DEST:$REMOTE_TMP_PATH
		ssh $DEST "cd $REMOTE_TMP_PATH ; tar zxvf package.tgz ; rm package.tgz ;"
		ssh $DEST "rm -rf $REMOTE_PATH; mv --force $REMOTE_TMP_PATH $REMOTE_PATH; echo $VERSION_NAME > $REMOTE_PATH/version.txt; cd $REMOTE_PATH; bash post-deploy.sh $ENV_NAME $ENV_NAME_CONFIG";
	else
		echo "This version is already deployed here. Execute with overwrite option";	
	fi
	echo "-- Done $DEST"
done

if [ ! -z "$EMAIL_LIST" ]
then
	echo "Email: $EMAIL_LIST";
	EMAIL_MESSAGE="Deployment Completed For: $PROJECT_NAME - $ENV_NAME - $VERSION_NAME\n\n\n----"
	echo -e $EMAIL_MESSAGE | mail -s "Deployment Completed - Beaver Deployment Tool" "$EMAIL_LIST"
	#echo -e $EMAIL_MESSAGE | mail -s "Deployment Completed - Beaver Deployment Tool" "$EMAIL_LIST" -- -f tomasz.rakowski@manwin.com
	
fi