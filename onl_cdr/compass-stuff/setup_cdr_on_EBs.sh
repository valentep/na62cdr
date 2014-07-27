#!/bin/bash

ct_obj_local="/var/spool/cron/objsrvvy"
ct_obj_master="/online/detector/cdr/master_crontab_objsrvvy"


# create needed directories in /tmp
if [ ! -d /tmp/ccf ]
then

  cd /tmp
  mkdir ccf
  chown objsrvvy:daq ccf

  cd ccf

  mkdir cdr
  mkdir onl_cdr
  chown -R objsrvvy:daq .
fi


# create needed directories in /data
if [ ! -d /data/bkm ]
then

  cd /data

  mkdir cdr
  mkdir bkm
  mkdir meta
  mkdir meta_castorok

  cd bkm

  mkdir OnlineDataComplete
  mkdir OnlineDataStop
  mkdir OnlineTransferStart
  mkdir OnlineTransferStop
  mkdir OnlineTransferComplete
  mkdir OnlineDataClear

  cd /data

  chown -R objsrvvy:daq cdr bkm meta meta_castorok
  chmod -R g+w cdr bkm meta meta_castorok
  
  cd /tmp
  mkdir ccf
  mkdir ccf/onl_cdr
  mkdir ccf/cdr
  chown -R objsrvvy:daq ccf
  chmod -R g+w ccf
  
fi


# update the objsrvvy crontab
if [ $ct_obj_master -nt $ct_obj_local ]
then
  crontab -u objsrvvy $ct_obj_master
fi

