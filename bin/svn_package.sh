#!/bin/sh

DOC_SVN_PATH=svn://10.1.16.88/vrvim/trunk/im/doc
FRAMEWORK_SVN_PATH=svn://10.1.16.88/vrvim/trunk/framework
SRC_C_SVN_PATH=svn://10.1.16.88/vrvim/trunk/im/srv_c
VRV_CPLUS_SERVER_SVN_PATH=svn://10.1.16.88/vrvim/trunk/im/srv_c/vrv-cplus-server
VRV_THRIFT_SVN_PATH=svn://10.1.16.88/vrvim/trunk/im/server/thrift
VRV_UPLOAD_SVN_PATH=svn://10.1.16.88/vrvim/trunk/im/imageserver/vrv_new_upload/upload_tmp
VRV_NGX_SVN_PATH=svn://10.1.16.88/vrvim/trunk/im/srv_c/ngx

VRV_PROJ_LOCAL_PATH=/home/vrv/vrv_im_package_proj
#VRV_PROJ_LOCAL_PATH=/home/xhding/workspace/vrv/dev_server_im_test2
VRV_THRIFT_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/thrift/vrv-thrift
DOC_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/doc
FRAMEWORK_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/framework
SRC_C_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/srv_c

#apns
APNS_BASE_LOCAL_PATH=$SRC_C_LOCAL_PATH/vrv-apns-new
APNS_LOCAL_PATH=$APNS_BASE_LOCAL_PATH/vrv-apns
APNS_CONFIG_LOCAL_PATH=$APNS_BASE_LOCAL_PATH/apns_conf
APNS_BUILD_LOCAL_PATH=$APNS_LOCAL_PATH/build
APNS_CONFIG_LOCAL_PATH=$APNS_LOCAL_PATH/config

#ap
VRV_CPLUS_LOCAL_PATH=$SRC_C_LOCAL_PATH/vrv-cplus-server
VRV_CPLUS_BUILD_PATH=$VRV_CPLUS_LOCAL_PATH/build
VRV_AP_LOCAL_PATH=$VRV_CPLUS_LOCAL_PATH/vrv_server
VRV_AP_CONFIG_LOCAL_PATH=$VRV_AP_LOCAL_PATH/config

#prelogin
VRV_PRELOGIN_LOACAL_PATH=$SRC_C_LOCAL_PATH/vrv-prelogin-golang
VRV_PRELOGIN_CONFIG_LOACAL_PATH=$VRV_PRELOGIN_LOACAL_PATH/config

#upload
VRV_UPLOAD_LOCAL_PATH=$SRC_C_LOCAL_PATH/upload_tmp
VRV_UPLOAD_BUILD_PATH=$SRC_C_LOCAL_PATH/upload_tmp/build
VRV_UPLOAD_CONFIG_PATH=$VRV_UPLOAD_LOCAL_PATH/conf

#ngx
VRV_NGX_CONFIG_FILE_LOCAL_PATH=$SRC_C_LOCAL_PATH/ngx

#log
LOG_INFO_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/vrv_package_log.log
APNS_LOG_INFO_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/vrv_apns_compile.log
AP_LOG_INFO_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/vrv_ap_compile.log
PRELOGIN_LOG_INFO_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/vrv_prelogin_compile.log
UPLOAD_LOG_INFO_LOCAL_PATH=$VRV_PROJ_LOCAL_PATH/vrv_upload_compile.log

#exec name
APNS_CONFIG_THRIFT_FILENAME=apns_serv.thrift
APNS_EXEC_NAME=APNS
APNS_AGENT_EXEC_NAME=agent_vrv
AP_EXEC_NAME=ap_vrv
PRELOGIN_EXEC_NAME=vrv-prelogin-golang  
UPLOAD_EXEC_NAME=upload.cgi  

#PROJ_NAME 0---apns, 1---ap, 2----prelogin, 3-----upload, 4----ngx
PROJ_NAME=$1
PROJ_VERSION=$2
PROJ_DOC_VERSION=$3
PROJ_THRIFT_VERSION=$4
REMOTE_PATH=$5
SCRIPT_EXEC_PATH=$6
EXEC_OUT_FILE_PATH=$SCRIPT_EXEC_PATH/result.txt

COMMIT_MID_NAME=_V

OUT_LOCAL_APNS_PATH=$APNS_BUILD_LOCAL_PATH/apns
OUT_LOCAL_AP_PATH=$VRV_CPLUS_BUILD_PATH/ap
OUT_LOCAL_PRELOGIN_PATH=$VRV_PRELOGIN_LOACAL_PATH/prelogin
OUT_LOCAL_UPLOAD_PATH=$VRV_UPLOAD_BUILD_PATH/upload

#OUT_LOCAL_APNS_PATH=$APNS_BUILD_LOCAL_PATH/$APNS_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION
#OUT_LOCAL_AP_PATH=$VRV_CPLUS_BUILD_PATH/$AP_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION
#OUT_LOCAL_PRELOGIN_PATH=$VRV_PRELOGIN_LOACAL_PATH/$PRELOGIN_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION
#OUT_LOCAL_UPLOAD_PATH=$VRV_UPLOAD_BUILD_PATH/$UPLOAD_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION

COMMIT_REMOTE_FILE_PATH=/home/serverupdate
COMMIT_REMOTE_IP_ADDR=210.14.152.187
COMMIT_REMOTE_USER=builder

#compile function
function Compile_APNS_Proj() {
    #cd $APNS_CONFIG_LOCAL_PATH
    cp -rf $APNS_CONFIG_LOCAL_PATH/$APNS_CONFIG_THRIFT_FILENAME $APNS_LOCAL_PATH

    [ ! -d $APNS_BUILD_LOCAL_PATH ] && {
        mkdir -p $APNS_BUILD_LOCAL_PATH
        #echo  $APNS_BUILD_LOCAL_PATH >> $APNS_LOG_INFO_LOCAL_PATH
    }

    cd $APNS_BUILD_LOCAL_PATH  && rm -rf * 

    [ $? -ne 0 ] && {
        echo " make apns build env failed in Time: $(date +%F-%T) " >> $APNS_LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    } 

    echo " start make apns in Time: $(date +%F-%T) " >> $APNS_LOG_INFO_LOCAL_PATH
    cmake $APNS_LOCAL_PATH && make clean && make >> $APNS_LOG_INFO_LOCAL_PATH

    [ $? -ne 0 ] && {
        echo " make apns project failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    } 

    echo " make apns project success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH

    [ ! -d $OUT_LOCAL_APNS_PATH ] && {
        mkdir -p $OUT_LOCAL_APNS_PATH
    }

    mv $APNS_BUILD_LOCAL_PATH/$APNS_EXEC_NAME $OUT_LOCAL_APNS_PATH
    cp -rf $APNS_CONFIG_LOCAL_PATH/* $OUT_LOCAL_APNS_PATH
}

function Compile_AP_Proj() {
    chmod a+x $VRV_AP_LOCAL_PATH/ -R
    $VRV_AP_LOCAL_PATH/gen-vrv-thrift.sh
    cd $VRV_CPLUS_LOCAL_PATH

    [ ! -d $VRV_CPLUS_BUILD_PATH ] && {
         mkdir -p $VRV_CPLUS_BUILD_PATH
    }

    cd $VRV_CPLUS_BUILD_PATH && rm -rf * 

    [ $? -ne 0 ] && {
        echo " make ap build env failed in Time: $(date +%F-%T) " >> $AP_LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    } 

    echo " start make ap in Time: $(date +%F-%T) " >> $AP_LOG_INFO_LOCAL_PATH
    cmake $VRV_CPLUS_LOCAL_PATH && make clean && make >> $AP_LOG_INFO_LOCAL_PATH

    [ $? -ne 0 ] && {
        echo " make ap project failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    } 

    echo " make ap project success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH

    [ ! -d $OUT_LOCAL_AP_PATH ] && {
        mkdir -p $OUT_LOCAL_AP_PATH
    }

    mv $VRV_CPLUS_BUILD_PATH/$AP_EXEC_NAME $OUT_LOCAL_AP_PATH
    mv $VRV_CPLUS_BUILD_PATH/$APNS_AGENT_EXEC_NAME $OUT_LOCAL_AP_PATH
    cp -rf $VRV_AP_CONFIG_LOCAL_PATH/* $OUT_LOCAL_AP_PATH
}

function Compile_PreLogin_Proj() {
    rm -rf $OUT_LOCAL_PRELOGIN_PATH/*
    export GOPATH=`pwd`
    go get github.com/cihub/seelog
    echo " start make prelogin in Time: $(date +%F-%T) " >> $PRELOGIN_LOG_INFO_LOCAL_PATH
    go build -x >> $PRELOGIN_LOG_INFO_LOCAL_PATH

    [ $? -ne 0 ] && {
        echo " make prelogin project failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    } 

    [ ! -d $OUT_LOCAL_PRELOGIN_PATH ] && {
        mkdir -p $OUT_LOCAL_PRELOGIN_PATH
    }

    mv $VRV_PRELOGIN_LOACAL_PATH/$PRELOGIN_EXEC_NAME $OUT_LOCAL_PRELOGIN_PATH/prelogin
    cp -rf $VRV_PRELOGIN_CONFIG_LOACAL_PATH/* $OUT_LOCAL_PRELOGIN_PATH
}

function Compile_UpLoad_Proj() {
    cd $VRV_UPLOAD_LOCAL_PATH
    [ ! -d $VRV_UPLOAD_BUILD_PATH ] && {
         mkdir -p $VRV_UPLOAD_BUILD_PATH
    }

    cd $VRV_UPLOAD_BUILD_PATH && rm -rf * 

    [ $? -ne 0 ] && {
        echo " make upload build env failed in Time: $(date +%F-%T) " >> $UPLOAD_LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    } 

    echo " start make upload in Time: $(date +%F-%T) " >> $UPLOAD_LOG_INFO_LOCAL_PATH
    cmake $VRV_UPLOAD_LOCAL_PATH && make clean && make >> $UPLOAD_LOG_INFO_LOCAL_PATH

    [ $? -ne 0 ] && {
        echo " make upload project failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    } 

    echo " make upload project success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH

    [ ! -d $OUT_LOCAL_UPLOAD_PATH ] && {
        mkdir -p $OUT_LOCAL_UPLOAD_PATH
    }

    mv $VRV_UPLOAD_BUILD_PATH/$UPLOAD_EXEC_NAME $OUT_LOCAL_UPLOAD_PATH
    cp -rf $VRV_UPLOAD_CONFIG_PATH $OUT_LOCAL_UPLOAD_PATH
}

function CreateRemotePath() {
    ssh $COMMIT_REMOTE_USER@$COMMIT_REMOTE_IP_ADDR "mkdir -p $REMOTE_PATH"
    [ $? -ne 0 ] && {
        echo " mkdir $REMOTE_PATH failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
        exit 0
    }
}

#commit exec
function Commit_APNS_Exec() {
    CreateRemotePath
    scp -r $OUT_LOCAL_APNS_PATH $COMMIT_REMOTE_USER@$COMMIT_REMOTE_IP_ADDR:$REMOTE_PATH
    [ $? -ne 0 ] && {
        echo " commit apns exec failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
    } || {
        echo " commit apns exec success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "1" > $EXEC_OUT_FILE_PATH
    } 
    exit 0
}

function Commit_AP_Exec() {
    CreateRemotePath
    scp -r $OUT_LOCAL_AP_PATH $COMMIT_REMOTE_USER@$COMMIT_REMOTE_IP_ADDR:$REMOTE_PATH
    [ $? -ne 0 ] && {
        echo " commit ap exec failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
    } || {
        echo " commit ap exec success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "1" > $EXEC_OUT_FILE_PATH
    } 
    exit 0
}

function Commit_PreLogin_Exec() {
    CreateRemotePath
    scp -r $OUT_LOCAL_PRELOGIN_PATH $COMMIT_REMOTE_USER@$COMMIT_REMOTE_IP_ADDR:$REMOTE_PATH
    [ $? -ne 0 ] && {
        echo " commit prelogin exec failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
    } || {
        echo " commit prelogin exec success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "1" > $EXEC_OUT_FILE_PATH
    } 
    
    exit 0
}

function Commit_UpLoad_Exec() {
    CreateRemotePath
    scp -r $OUT_LOCAL_UPLOAD_PATH $COMMIT_REMOTE_USER@$COMMIT_REMOTE_IP_ADDR:$REMOTE_PATH
    [ $? -ne 0 ] && {
        echo " commit upload exec failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
    } || {
        echo " commit upload exec success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "1" > $EXEC_OUT_FILE_PATH
    } 
    exit 0
}

function Commit_Ngx_Config_File() {
    CreateRemotePath
    scp -r $VRV_NGX_CONFIG_FILE_LOCAL_PATH/ngx* $COMMIT_REMOTE_USER@$COMMIT_REMOTE_IP_ADDR:$REMOTE_PATH
    [ $? -ne 0 ] && {
        echo " commit ngx config files failed in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "0" > $EXEC_OUT_FILE_PATH
    } || {
        echo " commit ngx config files success in Time: $(date +%F-%T) " >> $LOG_INFO_LOCAL_PATH
        echo "1" > $EXEC_OUT_FILE_PATH
    } 
    exit 0
}

function UpdateProj() {
    [[ $PROJ_VERSION -eq 0 ]] && { 
        svn update
        PROJ_VERSION=$(svn info | grep Revision: |awk '{print $2}') 

    } || svn update -r $PROJ_VERSION

    #if proj is ap, then update doc and thrift files
    [[ $PROJ_NAME -eq 1 ]] && {
        cd $DOC_LOCAL_PATH
        [[ $PROJ_DOC_VERSION -eq 0 ]] && {
            svn update
            PROJ_DOC_VERSION=$(svn info | grep Revision: |awk '{print $2}') 
        } || svn update -r $PROJ_DOC_VERSION
       
        echo "doc version $PROJ_DOC_VERSION" >> $LOG_INFO_LOCAL_PATH

        cd $VRV_THRIFT_LOCAL_PATH
        [[ $PROJ_THRIFT_VERSION -eq 0 ]] && {
            svn update
            PROJ_THRIFT_VERSION=$(svn info | grep Revision: |awk '{print $2}') 
        } || svn update -r $PROJ_THRIFT_VERSION

        echo "thrift version $PROJ_THRIFT_VERSION" >> $LOG_INFO_LOCAL_PATH
    }

    #OUT_LOCAL_APNS_PATH=$APNS_BUILD_LOCAL_PATH/$APNS_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION
    #OUT_LOCAL_AP_PATH=$VRV_CPLUS_BUILD_PATH/$AP_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION
    #OUT_LOCAL_PRELOGIN_PATH=$VRV_PRELOGIN_LOACAL_PATH/$PRELOGIN_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION
    #OUT_LOCAL_UPLOAD_PATH=$VRV_UPLOAD_BUILD_PATH/$UPLOAD_EXEC_NAME$COMMIT_MID_NAME$PROJ_VERSION
}

#create dir 
[ ! -d $VRV_PROJ_LOCAL_PATH ] && {
    mkdir -p $VRV_PROJ_LOCAL_PATH
    mkdir -p $VRV_THRIFT_LOCAL_PATH
    mkdir -p $DOC_LOCAL_PATH
    mkdir -p $FRAMEWORK_LOCAL_PATH
    mkdir -p $SRC_C_LOCAL_PATH
    mkdir -p $VRV_UPLOAD_SVN_PATH

    #check out
    svn co $DOC_SVN_PATH $DOC_LOCAL_PATH --username zhuxiaoqing150514 --password zxq150514
    svn co $VRV_THRIFT_SVN_PATH $VRV_THRIFT_LOCAL_PATH --username zhuxiaoqing150514 --password zxq150514
    svn co $FRAMEWORK_SVN_PATH $FRAMEWORK_LOCAL_PATH --username zhuxiaoqing150514 --password zxq150514
    svn co $SRC_C_SVN_PATH $SRC_C_LOCAL_PATH --username zhuxiaoqing150514 --password zxq150514
    svn co $VRV_UPLOAD_SVN_PATH $VRV_UPLOAD_LOCAL_PATH --username zhuxiaoqing150514 --password zxq150514
}

#rm -fr $LOG_INFO_LOCAL_PATH 
#update version
if [[ $PROJ_NAME -eq 0 ]]; then  #apns
    cd $APNS_LOCAL_PATH
    rm -fr $APNS_LOG_INFO_LOCAL_PATH
    UpdateProj
    echo "svn update apns project to version: $PROJ_VERSION in Time: $(date +%F-%T)" >> $LOG_INFO_LOCAL_PATH
    Compile_APNS_Proj
    Commit_APNS_Exec

elif [[ $PROJ_NAME -eq 1 ]]; then #ap
    #cd $VRV_AP_LOCAL_PATH
    cd $VRV_CPLUS_LOCAL_PATH
    rm -fr $AP_LOG_INFO_LOCAL_PATH
    UpdateProj
    echo "svn update ap project to version: $PROJ_VERSION in Time: $(date +%F-%T)" >> $LOG_INFO_LOCAL_PATH
    Compile_AP_Proj
    Commit_AP_Exec

elif [[ $PROJ_NAME -eq 2 ]]; then #prelogin
    cd $VRV_PRELOGIN_LOACAL_PATH
    rm -fr $PRELOGIN_LOG_INFO_LOCAL_PATH
    UpdateProj
    echo "svn update prelogin project to version: $PROJ_VERSION in Time: $(date +%F-%T)" >> $LOG_INFO_LOCAL_PATH
    Compile_PreLogin_Proj
    Commit_PreLogin_Exec

elif [[ $PROJ_NAME -eq 3 ]]; then #upload
    cd $VRV_UPLOAD_LOCAL_PATH
    rm -fr $UPLOAD_LOG_INFO_LOCAL_PATH
    UpdateProj
    echo "svn update upload project to version: $PROJ_VERSION in Time: $(date +%F-%T)" >> $LOG_INFO_LOCAL_PATH
    Compile_UpLoad_Proj
    Commit_UpLoad_Exec

elif [[ $PROJ_NAME -eq 4 ]]; then #ngx
    cd $VRV_NGX_CONFIG_FILE_LOCAL_PATH
    UpdateProj
    echo "svn update ngx config file to version: $PROJ_VERSION in Time: $(date +%F-%T)" >> $LOG_INFO_LOCAL_PATH
    Commit_Ngx_Config_File

else
    echo "PROJNAME argc is not support" >> $LOG_INFO_LOCAL_PATH
fi





