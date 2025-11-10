Вот типовые запросы для анализа текущего подключения в Oracle:

## 1. Текущий пользователь и сессия
```sql
SELECT 
    USER AS current_user,
    SYS_CONTEXT('USERENV', 'SESSION_USER') AS session_user,
    SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') AS current_schema,
    SYS_CONTEXT('USERENV', 'DB_NAME') AS database_name,
    SYS_CONTEXT('USERENV', 'INSTANCE_NAME') AS instance_name,
    SID, SERIAL# 
FROM V$SESSION 
WHERE AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID');
```

## 2. Роли и системные привилегии текущего пользователя
```sql
-- Роли пользователя
SELECT * FROM USER_ROLE_PRIVS;

-- Системные привилегии
SELECT * FROM USER_SYS_PRIVS;

-- Все привилегии (роли + системные)
SELECT * FROM SESSION_PRIVS;
```

## 3. Доступные схемы и права на объекты
```sql
-- Все схемы, к которым есть доступ
SELECT DISTINCT OWNER 
FROM ALL_OBJECTS 
WHERE OWNER NOT IN ('SYS','SYSTEM')
ORDER BY OWNER;

-- Права на таблицы в других схемах
SELECT OWNER, TABLE_NAME, PRIVILEGE, GRANTOR
FROM USER_TAB_PRIVS 
WHERE OWNER != USER;

-- Права на выполнение процедур/функций
SELECT OWNER, TABLE_NAME AS OBJECT_NAME, PRIVILEGE
FROM USER_TAB_PRIVS 
WHERE TABLE_NAME IN (SELECT OBJECT_NAME FROM USER_OBJECTS WHERE OBJECT_TYPE IN ('PROCEDURE','FUNCTION'))
UNION ALL
SELECT OWNER, OBJECT_NAME, PRIVILEGE
FROM USER_OBJ_PRIVS;
```

## 4. Информация о табличных пространствах и квотах
```sql
-- Доступные табличные пространства
SELECT TABLESPACE_NAME, BLOCKS, MAX_BLOCKS, BYTES, MAX_BYTES
FROM USER_TS_QUOTAS;

-- Права на табличные пространства
SELECT * FROM USER_SYS_PRIVS 
WHERE PRIVILEGE LIKE '%TABLESPACE%';
```

## 5. Детальная информация о сессии
```sql
-- Текущая сессия с деталями
SELECT 
    s.USERNAME,
    s.SCHEMANAME,
    s.OSUSER,
    s.MACHINE,
    s.PROGRAM,
    s.LOGON_TIME,
    s.STATUS
FROM V$SESSION s
WHERE s.AUDSID = SYS_CONTEXT('USERENV','SESSIONID');
```

## 6. Проверка доступа к системным представлениям
```sql
-- Проверка доступных системных представлений
SELECT TABLE_NAME 
FROM ALL_TABLES 
WHERE OWNER = 'SYS' 
AND TABLE_NAME LIKE 'V$%'
AND ROWNUM <= 10;
```

## 7. Права на пакеты и системные объекты
```sql
-- Доступ к стандартным пакетам Oracle
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM ALL_OBJECTS 
WHERE OWNER = 'SYS' 
AND OBJECT_TYPE = 'PACKAGE'
AND OBJECT_NAME IN ('DBMS_OUTPUT', 'UTL_FILE', 'DBMS_JOB', 'DBMS_SCHEDULER')
ORDER BY OBJECT_NAME;
```

## 8. Комплексный запрос для быстрого анализа
```sql
SELECT 
    'Current User: ' || USER as info,
    'Current Schema: ' || SYS_CONTEXT('USERENV','CURRENT_SCHEMA') as schema_info,
    'Database: ' || SYS_CONTEXT('USERENV','DB_NAME') as db_info,
    'Instance: ' || SYS_CONTEXT('USERENV','INSTANCE_NAME') as instance_info
FROM DUAL
UNION ALL
SELECT 'Roles: ' || LISTAGG(GRANTED_ROLE, ', ') WITHIN GROUP (ORDER BY GRANTED_ROLE), '', ''
FROM USER_ROLE_PRIVS
UNION ALL
SELECT 'Sys Privileges: ' || LISTAGG(PRIVILEGE, ', ') WITHIN GROUP (ORDER BY PRIVILEGE), '', ''
FROM USER_SYS_PRIVS;
```


## Ключевые моменты для анализа:
- **CURRENT_SCHEMA** - текущая схема по умолчанию
- **SESSION_PRIVS** - все доступные привилегии (включая через роли)
- **USER_TAB_PRIVS** - права на таблицы в других схемах
- **USER_ROLE_PRIVS** - назначенные роли
