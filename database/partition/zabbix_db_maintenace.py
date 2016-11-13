#!/usr/bin/env python
import psycopg2,logging

################
# const values #
################

host='127.0.0.1'
user='zabbix'
pw='zabbix'
db='zabbix'

history_old=30
history_new=3
trend_old=12
trend_new=3
tablespace='repo'

logfile='zabbix_db_maintenace.log'
################
#  log config  #
################

logger=logging.getLogger('zabbix_db_maintenace')
fh=logging.FileHandler(logfile)
formater=logging.Formatter('%(asctime)s %(levelname)s %(message)s')
fh.setFormatter(formater)
logger.addHandler(fh)
logger.setLevel(logging.DEBUG)


#################
# main function #
#################


#partition maintenace
try:
    con=psycopg2.connect(host=host,database=db,user=user,password=pw)
    cur=con.cursor()
    logger.info('start partition maintenace')
    cur.execute('SELECT zabbix_make_partition(%s,%s,%s,%s,\'%s\')'%(
            history_old,
            history_new,
            trend_old,
            trend_new,
            tablespace))
    con.commit()	
    cur.close()
except Exception as e:
    logger.error('partition maintenace fail,reason: ')
    logger.error(e)

else:
    logger.info('partition maintenace finish')
finally:
    con.close() 

