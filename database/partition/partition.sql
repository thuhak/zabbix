CREATE SCHEMA IF NOT EXISTS partitions AUTHORIZATION zabbix;

CREATE OR REPLACE FUNCTION zabbix_make_partition(history_old INTEGER,history_new INTEGER,trend_old INTEGER,trend_new INTEGER,tablespace VARCHAR DEFAULT NULL,owner VARCHAR DEFAULT 'zabbix')
RETURNS VOID AS $BODY$
from datetime import datetime,date
from calendar import monthrange
try:
    from dateutil.relativedelta import relativedelta
except ImportError:
    plpy.error('you should install python-dateutil first,eg:pip3 install python-dateutil')
    raise
try:
    from jinja2 import Template
except ImportError:
    plpy.error('you should install jinja2 first,eg:pip3 install jinja2')
    raise

###################
# parameter check #
###################

usage='''
zabbix_make_partition(history_old,history_new,trend_old,trend_new,tablespace,owner='zabbix')

parameters:
history_old -> how many old history partitions you wanna keep,0 means delete all.
history_new -> how many new history partitions you wanna create,0 means delete all.
trend_old -> how many old trend partitions you wanna keep,0 means delete all.
trend_new -> how many new trend partitions you wanna create,0 means delete all.
tablespace -> tablespace you wanna store history and trends partitions.
owner -> owner of tables,default set to 'zabbix'
'''

if (history_old < 0) or (history_new < 0) or (trend_old < 0) or (trend_new < 0):
    plpy.error('all partition number should be no negetive')
    plpy.notice(usage)
    return

user_check=len(plpy.execute('SELECT 1 FROM pg_user WHERE usename = %s'%(plpy.quote_literal(owner))))
if user_check == 0:
    plpy.error=('there is no user:%s'%owner)
    return

if tablespace is not None:
    tablespace_check=len(plpy.execute('SELECT 1 FROM pg_tablespace WHERE spcname = %s'%plpy.quote_literal(tablespace)))
    if tablespace_check == 0:
        plpy.error('there is no tablespace:%s'%tablespace)
        return 

##################
#  const values  #
##################

history_tables=['history','history_log','history_str','history_uint','history_text']
trend_tables=['trends','trends_uint']

today=date.today()

######################
#  helper functions  #
######################

def _get_clock_range(clock):
    '''
    transfer yyyymm or yyyymmdd format to timestamp range.
    eg:
    INPUT: '201610' => OUTPUT: ('1477584000','1477670399')
    INPUT: '20160930' => OUTPUT: ('1475164800','1475251199')
    '''  
    if len(clock) == 6:
        y=int(clock[:4])
        m=int(clock[4:])
        start_clock='%d' % datetime(y,m,1).timestamp()
        days=monthrange(y,m)[1]
        end_clock='%d' % datetime(y,m,days,23,59,59).timestamp()
        return (start_clock,end_clock)
    elif len(clock) == 8:
        y=int(clock[:4])
        m=int(clock[4:6])
        d=int(clock[6:])
        start_clock='%d' % datetime(y,m,d).timestamp()
        end_clock='%d' % datetime(y,m,d,23,59,59).timestamp()
        return (start_clock,end_clock)
    else:
        plpy.error('time format error')

def _dates_or_months(date,counts,month=False):
    '''
    return dates using yyyymmdd or yyyymm format from date 
    eg:
    date: date(2016,11,1) month:False
    INPUT: counts:3 => OUTPUT: {'20161102','20161103','20161101'}
    INPUT: counts:-3 => OUTPUT: {'20161030','20161031','20161029'}
    date: date(2016,9,21) month:True
    INPUT: counts:3 => OUTPUT: {'201609','201610','201611'}
    INPUT: counts:-3 => OUTPUT: {'201608','201607','201606'}
    '''
    asset=set()
    if not month:
        if counts >= 0:
            for d in range(counts):
                dt=date+relativedelta(days=d) 
                asset.add(dt.strftime('%Y%m%d'))
        else:
            for d in range(1,1-counts):
                dt=date-relativedelta(days=d)
                asset.add(dt.strftime('%Y%m%d'))
    else:
        if counts >= 0:
            for m in range(counts):
                dm=date+relativedelta(months=m)
                asset.add(dm.strftime('%Y%m'))
        else:
            for m in range(1,1-counts):
                dm=date-relativedelta(months=m)
                asset.add(dm.strftime('%Y%m'))
    return asset


######################
#  trigger function  #
######################
# need jinja2 template 

trigger='''CREATE OR REPLACE FUNCTION {{ func_name }}()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.clock >= {{ record[0][1] }} AND NEW.clock <= {{ record[0][2] }} THEN
      INSERT INTO partitions.{{ record[0][0] }} VALUES (NEW.*);
  {% for table in record[1:] %}
    ELSEIF NEW.clock >= {{ table[1] }} AND NEW.clock <= {{ table[2] }} THEN
      INSERT INTO partitions.{{ table[0] }} VALUES (NEW.*);
  {% endfor %}
    ELSE
      RAISE EXCEPTION 'out of table range';
    END IF;
  END IF;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;'''

def create_trigger(table,target):
    records=[]
    func_name='insert_'+table+'_trigger'
    trig_name=table+'_insert_trigger'
    if len(target) == 0:
        plpy.execute('DROP TRIGGER IF EXISTS %s ON %s CASCADE'%(plpy.quote_ident(trig_name),plpy.quote_ident(table)))
        plpy.execute('DROP FUNCTION IF EXISTS %s() CASCADE'%plpy.quote_ident(func_name))
        return
    else:
        for record in target:
            start,end=_get_clock_range(record)
            records.append((table+'_'+record,start,end))
        temp=Template(trigger)
        trig_func=temp.render(func_name=func_name,record=records)
        exist_trig=len(plpy.execute('SELECT 1 FROM pg_trigger WHERE tgname = %s'%plpy.quote_literal(trig_name)))
        create_trig='CREATE TRIGGER %s BEFORE INSERT ON %s FOR EACH ROW EXECUTE PROCEDURE %s();'%(
                                    plpy.quote_ident(trig_name),
                                    plpy.quote_ident(table),
                                    plpy.quote_ident(func_name))
        try:
            with plpy.subtransaction():
                plpy.execute(trig_func)
                if not exist_trig:
                    plpy.execute(create_trig)
        except plpy.SPIError as e:
            plpy.error(e)
            raise
 
######################
#  create partition  #
######################

def create_childtable(master_table,child_suffix,tablespace,table_owner):
    table_owner=owner
    start_clock,end_clock=_get_clock_range(child_suffix)
    child_table=master_table+'_'+child_suffix
    if tablespace is None:
        ts=''
    else:
        ts='TABLESPACE '+tablespace
    create_table='CREATE UNLOGGED TABLE IF NOT EXISTS partitions.%s (CHECK (clock >= %s AND clock <=%s), LIKE %s INCLUDING ALL) %s'%(
                     plpy.quote_ident(child_table),
                     plpy.quote_literal(start_clock),
                     plpy.quote_literal(end_clock),
                     plpy.quote_ident(master_table),
                     ts)
    alter_table_inherit='ALTER TABLE partitions.%s INHERIT %s'%(
            plpy.quote_ident(child_table),
            plpy.quote_ident(master_table))
    alter_table_user='ALTER TABLE partitions.%s OWNER TO %s'%(
            plpy.quote_ident(child_table),
            plpy.quote_ident(table_owner))
    try:
        with plpy.subtransaction():
                plpy.execute(create_table)
                plpy.execute(alter_table_inherit)
                plpy.execute(alter_table_user)
    except plpy.SPIError:
        plpy.error('can not create table')
        raise


target_history=_dates_or_months(today,-history_old) | _dates_or_months(today,history_new)
target_trend=_dates_or_months(today,-trend_old,month=True) | _dates_or_months(today,trend_new,month=True)

create_partitions={}
delete_partitions={}

for table in history_tables:
    childtables=plpy.execute("SELECT tablename FROM pg_tables WHERE tablename SIMILAR TO '%s_\d{8}'"%table)
    old_partition={t['tablename'][-8:] for t in childtables}
    create_partitions[table] = target_history-old_partition
    delete_partitions[table] = ['%s_%s'%(table,i) for i in old_partition-target_history]

for table in trend_tables:
    childtables=plpy.execute("SELECT tablename FROM pg_tables WHERE tablename SIMILAR TO '%s_\d{6}'"%table)
    old_partition={t['tablename'][-6:] for t in childtables}
    create_partitions[table] = target_trend-old_partition
    delete_partitions[table] = ['%s_%s'%(table,i) for i in old_partition-target_trend]

for table in history_tables+trend_tables:
    try:
        for child_suffix in create_partitions[table]:
            create_childtable(table,child_suffix,tablespace=tablespace,table_owner=owner)
        if table in history_tables:
            create_trigger(table,target_history)
        else:
            create_trigger(table,target_trend)
        for table in delete_partitions[table]:
            plpy.execute("DROP TABLE partitions.%s"%(plpy.quote_ident(table)))
    except plpy.SPIError as e:
        plpy.error('zabbix partition maintenece job failed')
$BODY$ LANGUAGE plpython3u VOLATILE;

ALTER FUNCTION zabbix_make_partition(INTEGER,INTEGER,INTEGER,INTEGER,VARCHAR,VARCHAR) OWNER TO zabbix;
