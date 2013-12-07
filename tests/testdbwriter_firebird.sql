/********************* ROLES **********************/

/********************* UDFS ***********************/

/****************** GENERATORS ********************/

CREATE GENERATOR GEN_APPLICATIONS_ID;
CREATE GENERATOR GEN_CPU_ID;
CREATE GENERATOR GEN_EXCEPTIONCLASSES_ID;
CREATE GENERATOR GEN_EXCEPTIONMESSAGES_ID;
CREATE GENERATOR GEN_METHODNAMES_ID;
CREATE GENERATOR GEN_OS_ID;
CREATE GENERATOR GEN_RESULTVALUES_ID;
CREATE GENERATOR GEN_SOURCELOCATIONS_ID;
CREATE GENERATOR GEN_SOURCEUNITS_ID;
CREATE GENERATOR GEN_TESTRESULTS_ID;
CREATE GENERATOR GEN_TESTRUNS_ID;
CREATE GENERATOR GEN_TESTSUITES_ID;
CREATE GENERATOR GEN_TESTS_ID;
/******************** DOMAINS *********************/

/******************* PROCEDURES ******************/

SET TERM ^ ;
CREATE PROCEDURE RECALCINDEXES
AS
BEGIN SUSPEND; END^
SET TERM ; ^

/******************** TABLES **********************/

CREATE TABLE APPLICATIONS
(
  ID INTEGER NOT NULL,
  NAME VARCHAR(800) NOT NULL,
  CONSTRAINT APPPK PRIMARY KEY (ID),
  CONSTRAINT APPNAMEUNIQ UNIQUE (NAME)
);
CREATE TABLE CPU
(
  ID INTEGER NOT NULL,
  CPUNAME VARCHAR(128) NOT NULL,
  CONSTRAINT CPUPK PRIMARY KEY (ID),
  CONSTRAINT CPUUNIQUE UNIQUE (CPUNAME)
);
CREATE TABLE EXCEPTIONCLASSES
(
  ID INTEGER NOT NULL,
  EXCEPTIONCLASS VARCHAR(128) NOT NULL,
  CONSTRAINT EXCEPTIONSPK PRIMARY KEY (ID),
  CONSTRAINT UNQ_EXCEPTIONCLASSES_CLASS UNIQUE (EXCEPTIONCLASS)
);
CREATE TABLE EXCEPTIONMESSAGES
(
  ID INTEGER NOT NULL,
  EXCEPTIONCLASS INTEGER NOT NULL,
  EXCEPTIONMESSAGE VARCHAR(800) NOT NULL,
  CONSTRAINT EXCEPTIONMESSAGESPK PRIMARY KEY (ID),
  CONSTRAINT EXCEPTIONMESSAGEUNIQUE UNIQUE (EXCEPTIONMESSAGE)
);
CREATE TABLE METHODNAMES
(
  ID INTEGER NOT NULL,
  NAME VARCHAR(128) NOT NULL,
  CONSTRAINT METHODNAMESPK PRIMARY KEY (ID),
  CONSTRAINT METHODNAMESUNIQUENAME UNIQUE (NAME)
);
CREATE TABLE OPTIONS
(
  OPTIONNAME VARCHAR(255) NOT NULL,
  OPTIONVALUE VARCHAR(255),
  REMARKS VARCHAR(255),
  CONSTRAINT OPTIONSPK PRIMARY KEY (OPTIONNAME)
);
CREATE TABLE OS
(
  ID INTEGER NOT NULL,
  OSNAME VARCHAR(128) NOT NULL,
  CONSTRAINT OSPK PRIMARY KEY (ID),
  CONSTRAINT OSUNIQUE UNIQUE (OSNAME)
);
CREATE TABLE RESULTVALUES
(
  ID INTEGER NOT NULL,
  NAME VARCHAR(64) NOT NULL,
  CONSTRAINT RESULTVALUESPK PRIMARY KEY (ID),
  CONSTRAINT UNQ_RESULTVALUES_NAME UNIQUE (NAME)
);
CREATE TABLE SOURCELOCATIONS
(
  ID INTEGER NOT NULL,
  SOURCEUNIT INTEGER NOT NULL,
  LINE INTEGER,
  CONSTRAINT SOURCELOCATIONSPK PRIMARY KEY (ID),
  CONSTRAINT SOURCELOCATIONSUNIQUE UNIQUE (SOURCEUNIT,LINE)
);
CREATE TABLE SOURCEUNITS
(
  ID INTEGER NOT NULL,
  NAME VARCHAR(128) NOT NULL,
  CONSTRAINT SOURCEUNITS_PK PRIMARY KEY (ID),
  CONSTRAINT SOURCEUNITS_NAME_UNIQUE UNIQUE (NAME)
);
CREATE TABLE TESTRESULTS
(
  ID INTEGER NOT NULL,
  TESTRUN INTEGER NOT NULL,
  TEST INTEGER NOT NULL,
  RESULTVALUE INTEGER,
  EXCEPTIONMESSAGE INTEGER,
  METHODNAME INTEGER,
  SOURCELOCATION INTEGER,
  RESULTCOMMENT VARCHAR(800),
  ELAPSEDTIME TIME,
  CONSTRAINT TESTRESULTSPK PRIMARY KEY (ID)
);
CREATE TABLE TESTRUNS
(
  ID INTEGER NOT NULL,
  DATETIMERAN TIMESTAMP,
  APPLICATIONID INTEGER,
  CPU INTEGER,
  OS INTEGER,
  REVISIONID VARCHAR(64),
  RUNCOMMENT VARCHAR(800),
  TOTALELAPSEDTIME TIME,
  CONSTRAINT TESTRUNSPK PRIMARY KEY (ID)
);
CREATE TABLE TESTS
(
  ID INTEGER NOT NULL,
  TESTSUITE INTEGER NOT NULL,
  NAME VARCHAR(128) NOT NULL,
  CONSTRAINT TESTSPK PRIMARY KEY (ID),
  CONSTRAINT UNQ_TESTS UNIQUE (TESTSUITE,NAME)
);
CREATE TABLE TESTSUITES
(
  ID INTEGER NOT NULL,
  PARENTSUITE INTEGER,
  NAME VARCHAR(128) NOT NULL,
  DEPTH INTEGER,
  CONSTRAINT TESTSUITESPK PRIMARY KEY (ID),
  CONSTRAINT UNQ_TESTSUITES_NAMEPAR UNIQUE (PARENTSUITE,NAME)
);
/********************* VIEWS **********************/
CREATE VIEW TESTSUITESFLAT (TESTSUITEID, TESTSUITENAME, DEPTH)
AS  
with recursive suite_tree as (
  select id as testsuiteid, name as testsuitename, depth from TESTSUITES
  where parentsuite is null
union all
  select chi.id as testsuiteid, par.testsuitename||'/'||chi.name as testsuitename, chi.depth from testsuites chi
  join suite_tree par on chi.parentsuite=par.testsuiteid
)
select testsuiteid,testsuitename,depth from suite_tree;

CREATE VIEW FLAT (TESTRUNID, TESTRESULTID, TESTID, APPLICATION, REVISIONID, RUNCOMMENT, TESTRUNDATE, OS, CPU, TESTSUITE, TESTSUITEDEPTH, TESTNAME, TESTRESULT, EXCEPTIONCLASS, EXCEPTIONMESSAGE, METHOD, SOURCELINE, SOURCEUNIT, ELAPSEDTIME)
AS               
SELECT 
R.ID as TESTRUNID, 
TR.ID as TESTRESULTID,
T.ID as TESTID,
AP.NAME as APPLICATION,
R.REVISIONID, 
R.RUNCOMMENT, 
R.DATETIMERAN as TESTRUNDATE,
OS.OSNAME,
CP.CPUNAME,
S.TESTSUITENAME as TESTSUITE,
S.DEPTH as TESTSUITEDEPTH,
T.NAME as TESTNAME,
RV.NAME as RESULT,
E.EXCEPTIONCLASS,
EM.EXCEPTIONMESSAGE as EXCEPTIONMESSAGE,
M.NAME as METHOD,
SL.LINE as SOURCELINE,
SU.NAME as SOURCEUNIT,
TR.ELAPSEDTIME as ELAPSEDTIME
FROM TESTRUNS R inner join TESTRESULTS TR on R.ID=TR.TESTRUN
inner join TESTS T on TR.TEST=T.ID
inner join TESTSUITESFLAT S on T.TESTSUITE=S.TESTSUITEID
inner join RESULTVALUES RV on TR.RESULTVALUE=RV.ID
left join APPLICATIONS AP on R.APPLICATIONID=AP.ID
left join
EXCEPTIONMESSAGES EM on TR.EXCEPTIONMESSAGE=EM.ID
left join EXCEPTIONCLASSES E on EM.EXCEPTIONCLASS=E.ID
left join METHODNAMES M on TR.METHODNAME=M.ID
left join SOURCELOCATIONS SL on TR.SOURCELOCATION=SL.ID
left join SOURCEUNITS SU on SL.SOURCEUNIT=SU.ID
left join OS on R.OS=OS.ID
left join CPU CP on R.CPU=CP.ID;
CREATE VIEW FLATSORTED (TESTRUNID, TESTRESULTID, TESTID, APPLICATION, REVISIONID, RUNCOMMENT, TESTRUNDATE, OS, CPU, TESTSUITE, TESTSUITEDEPTH, TESTNAME, TESTRESULT, EXCEPTIONCLASS, EXCEPTIONMESSAGE, METHOD, SOURCELINE, SOURCEUNIT)
AS    
select
    f.TESTRUNID, f.TESTRESULTID, f.TESTID, 
    f.APPLICATION, f.REVISIONID,
    f.RUNCOMMENT, f.TESTRUNDATE, f.OS, f.CPU,
    f.TESTSUITE, f.TESTSUITEDEPTH, f.TESTNAME, f.TESTRESULT,
    f.EXCEPTIONCLASS, f.EXCEPTIONMESSAGE,
    f.METHOD, f.SOURCELINE, f.SOURCEUNIT from 
flat f
order by f.TESTRUNDATE desc, f.application, f.revisionid, f.TESTSUITEDEPTH, f.TESTSUITE, f.TESTNAME;
CREATE VIEW LASTFAILURE (APPLICATIONID, OSID, CPUID, TESTID, LASTFAILURE)
AS           
SELECT tr.applicationid, tr.os, tr.cpu, r.test,
max(cast(tr.revisionid as integer)) lastsuccess
FROM testresults r inner join resultvalues rv 
on r.RESULTVALUE=rv.id 
inner join testruns tr 
on r.testrun=tr.ID
where (rv.name='Failed') or (rv.name='Error')
group by tr.applicationid, tr.os, tr.cpu, r.test;
CREATE VIEW LASTSUCCESS (APPLICATIONID, OSID, CPUID, TESTID, LASTSUCCESS)
AS          
SELECT tr.applicationid, tr.os, tr.cpu, r.test,
max(cast(tr.revisionid as integer)) lastsuccess
FROM testresults r inner join resultvalues rv 
on r.RESULTVALUE=rv.id 
inner join testruns tr 
on r.testrun=tr.ID
where rv.name='OK'
group by tr.applicationid, tr.os, tr.cpu, r.test;
CREATE VIEW OKRESULTS (RUNID, APPLICATION, OS, CPU, OKCOUNT, OKPERCENTAGE)
AS   
SELECT run.id, a.name, o.osname, c.cpuname, count(rv.name), 
((count(tr.resultvalue))*100)/(SELECT COUNT(resultvalue) FROM testresults where testresults.testrun=run.id)
from
testresults tr inner join
testruns run on tr.TESTRUN=run.id inner JOIN
resultvalues rv on tr.resultvalue=rv.id
inner join applications a on run.applicationid=a.ID
inner join cpu c on run.cpu=c.ID
inner join os o on run.os=o.id
group by run.id, a.name, o.osname, c.cpuname, rv.name
having rv.name='OK';
CREATE VIEW REGRESSIONS (APPLICATIONID, CPUID, OSID, TESTID, LASTSUCCESFULREVISION)
AS     
select
s.applicationid, s.cpuid, s.osid, s.testid, s.lastsuccess as lastsuccessfulrevision
from
lastfailure f inner join lastsuccess s on 
(f.osid=s.osid) and
(f.cpuid=s.cpuid) and
(f.applicationid=s.applicationid) and (f.testid=s.testid)
where f.lastfailure>s.lastsuccess;
CREATE VIEW REGRESSIONSFLAT (TESTRUNID, APPLICATION, LASTSUCCESFULREVISION, TESTRUNDATE, OS, CPU, TESTSUITE, TESTNAME)
AS        
select 
run.id, 
a.NAME,
r.LASTSUCCESFULREVISION,
run.DATETIMERAN,
o.OSNAME,
c.CPUNAME,
ts.TESTSUITENAME,
t.NAME
from 
regressions r inner join testresults tr on
(r.testid=tr.test) 
inner join testruns run on
(r.applicationid=run.APPLICATIONID) AND
(r.osid=run.os) AND
(r.cpuid=run.cpu) AND
(tr.testrun=run.id) AND
(r.lastsuccesfulrevision=run.revisionid)
inner join applications a on run.applicationid=a.ID
inner join cpu c on run.cpu=c.ID
inner join os o on run.os=o.id
inner join tests t on tr.test=t.ID
inner join TESTSUITESFLAT ts on t.TESTSUITE=ts.TESTSUITEID;

/******************* EXCEPTIONS *******************/

/******************** TRIGGERS ********************/

SET TERM ^ ;
CREATE TRIGGER APPLICATIONS_BI FOR APPLICATIONS ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_APPLICATIONS_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_APPLICATIONS_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_APPLICATIONS_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER CPU_BI FOR CPU ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_CPU_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_CPU_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_CPU_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER EXCEPTIONCLASSES_BI FOR EXCEPTIONCLASSES ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_EXCEPTIONCLASSES_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_EXCEPTIONCLASSES_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_EXCEPTIONCLASSES_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER EXCEPTIONMESSAGES_BI FOR EXCEPTIONMESSAGES ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_EXCEPTIONMESSAGES_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_EXCEPTIONMESSAGES_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_EXCEPTIONMESSAGES_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER METHODNAMES_BI FOR METHODNAMES ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_METHODNAMES_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_METHODNAMES_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_METHODNAMES_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER OS_BI FOR OS ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_OS_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_OS_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_OS_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER RESULTVALUES_BI FOR RESULTVALUES ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_RESULTVALUES_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_RESULTVALUES_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_RESULTVALUES_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER SOURCELOCATIONS_BI FOR SOURCELOCATIONS ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_SOURCELOCATIONS_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_SOURCELOCATIONS_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_SOURCELOCATIONS_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER SOURCEUNITS_BI FOR SOURCEUNITS ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_SOURCEUNITS_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_SOURCEUNITS_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_SOURCEUNITS_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TESTRESULTS_BI FOR TESTRESULTS ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_TESTRESULTS_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_TESTRESULTS_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_TESTRESULTS_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TESTRUNS_BI FOR TESTRUNS ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_TESTRUNS_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_TESTRUNS_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_TESTRUNS_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TESTSUITES_BI FOR TESTSUITES ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_TESTSUITES_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_TESTSUITES_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_TESTSUITES_ID, new.ID-tmp);
  END
END^
SET TERM ; ^
SET TERM ^ ;
CREATE TRIGGER TESTS_BI FOR TESTS ACTIVE
BEFORE INSERT POSITION 0
AS
DECLARE VARIABLE tmp DECIMAL(18,0);
BEGIN
  IF (NEW.ID IS NULL) THEN
    NEW.ID = GEN_ID(GEN_TESTS_ID, 1);
  ELSE
  BEGIN
    tmp = GEN_ID(GEN_TESTS_ID, 0);
    if (tmp < new.ID) then
      tmp = GEN_ID(GEN_TESTS_ID, new.ID-tmp);
  END
END^
SET TERM ; ^

SET TERM ^ ;
ALTER PROCEDURE RECALCINDEXES
AS
declare variable index_name VARCHAR(31);
BEGIN
for select RDB$INDEX_NAME from RDB$INDICES into :index_name do
execute statement 'SET statistics INDEX ' || :index_name || ';';
END^
SET TERM ; ^

UPDATE RDB$PROCEDURES set
  RDB$DESCRIPTION = 'Recalculates index selectivity for all tables. This is normally only done during backup/restore etc, and can be useful after adding or removing a lot of data.'
  where RDB$PROCEDURE_NAME = 'RECALCINDEXES';

ALTER TABLE EXCEPTIONMESSAGES ADD CONSTRAINT FK_EXCEPTIONCLASSES_CLASS
  FOREIGN KEY (EXCEPTIONCLASS) REFERENCES EXCEPTIONCLASSES (ID) ON UPDATE CASCADE ON DELETE CASCADE;
UPDATE RDB$RELATIONS set
RDB$DESCRIPTION = 'Stores schema version and any application-specific options.'
where RDB$RELATION_NAME = 'OPTIONS';
ALTER TABLE SOURCELOCATIONS ADD CONSTRAINT SOURCELOCATIONSFK_UNIT
  FOREIGN KEY (SOURCEUNIT) REFERENCES SOURCEUNITS (ID) ON UPDATE CASCADE ON DELETE CASCADE;
UPDATE RDB$RELATION_FIELDS set RDB$DESCRIPTION = 'Name of the pascal unit'  where RDB$FIELD_NAME = 'NAME' and RDB$RELATION_NAME = 'SOURCEUNITS';
UPDATE RDB$RELATIONS set
RDB$DESCRIPTION = 'Pascal units where errrors occurred'
where RDB$RELATION_NAME = 'SOURCEUNITS';
UPDATE RDB$RELATION_FIELDS set RDB$DESCRIPTION = 'Note: let''s not use COMMENT as it is reserved in Firebird'  where RDB$FIELD_NAME = 'RESULTCOMMENT' and RDB$RELATION_NAME = 'TESTRESULTS';
ALTER TABLE TESTRESULTS ADD CONSTRAINT FK_TESTRES_EXCEPTION
  FOREIGN KEY (EXCEPTIONMESSAGE) REFERENCES EXCEPTIONMESSAGES (ID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TESTRESULTS ADD CONSTRAINT FK_TESTRES_RESULT
  FOREIGN KEY (RESULTVALUE) REFERENCES RESULTVALUES (ID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TESTRESULTS ADD CONSTRAINT FK_TESTRES_SOURCELOCATION
  FOREIGN KEY (SOURCELOCATION) REFERENCES SOURCELOCATIONS (ID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TESTRESULTS ADD CONSTRAINT FK_TESTRES_TEST
  FOREIGN KEY (TEST) REFERENCES TESTS (ID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TESTRESULTS ADD CONSTRAINT FK_TESTRES_TESTRUN
  FOREIGN KEY (TESTRUN) REFERENCES TESTRUNS (ID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TESTRESULTS ADD CONSTRAINT FK_TESTSRES_METHODNAME
  FOREIGN KEY (METHODNAME) REFERENCES METHODNAMES (ID) ON UPDATE CASCADE ON DELETE CASCADE;
UPDATE RDB$RELATION_FIELDS set RDB$DESCRIPTION = 'Identifies operating system the test application runs on'  where RDB$FIELD_NAME = 'OS' and RDB$RELATION_NAME = 'TESTRUNS';
UPDATE RDB$RELATION_FIELDS set RDB$DESCRIPTION = 'String that uniquely identifies the revision/version of the code that is tested. Useful when running regression tests, identifying when an error occurred first etc.'  where RDB$FIELD_NAME = 'REVISIONID' and RDB$RELATION_NAME = 'TESTRUNS';
UPDATE RDB$RELATION_FIELDS set RDB$DESCRIPTION = 'Comment provided by user/test run suite on this test run (e.g. used compiler flags)'  where RDB$FIELD_NAME = 'RUNCOMMENT' and RDB$RELATION_NAME = 'TESTRUNS';
ALTER TABLE TESTRUNS ADD CONSTRAINT FK_TESTRUNSCPU
  FOREIGN KEY (CPU) REFERENCES CPU (ID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TESTRUNS ADD CONSTRAINT FK_TESTRUNSOS
  FOREIGN KEY (OS) REFERENCES OS (ID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE TESTRUNS ADD CONSTRAINT FK_TESTRUNS_APPLICATIONS
  FOREIGN KEY (APPLICATIONID) REFERENCES APPLICATIONS (ID) ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX IDX_TESTRUNSCOMM ON TESTRUNS (RUNCOMMENT);
CREATE DESCENDING INDEX IDX_TESTRUNSDTREV ON TESTRUNS (DATETIMERAN);
CREATE INDEX IDX_TESTRUNSREV ON TESTRUNS (REVISIONID);
UPDATE RDB$RELATIONS set
RDB$DESCRIPTION = 'Represents a run by a single program of one or more testsuites'
where RDB$RELATION_NAME = 'TESTRUNS';
ALTER TABLE TESTS ADD CONSTRAINT TESTSTESTSUITESFK
  FOREIGN KEY (TESTSUITE) REFERENCES TESTSUITES (ID) ON UPDATE CASCADE ON DELETE CASCADE;
UPDATE RDB$RELATIONS set
RDB$DESCRIPTION = 'Name and testsuite (hierarchy) for a specific test. 

This table uniquely identifies tests, no need to add joins to testsuite.'
where RDB$RELATION_NAME = 'TESTS';
UPDATE RDB$RELATION_FIELDS set RDB$DESCRIPTION = 'Level in the hierarchy this testsuite has.'  where RDB$FIELD_NAME = 'DEPTH' and RDB$RELATION_NAME = 'TESTSUITES';
ALTER TABLE TESTSUITES ADD CONSTRAINT FK_TESTSUITES_PARENT
  FOREIGN KEY (PARENTSUITE) REFERENCES TESTSUITES (ID) ON UPDATE CASCADE ON DELETE CASCADE;
UPDATE RDB$RELATIONS set
  RDB$DESCRIPTION = 'Flattens the hierarchical tree of the testsuites and displays the name much like a path, including it depth in the hierarchy, for display and selection purposes.'
  where RDB$RELATION_NAME = 'TESTSUITESFLAT';
GRANT EXECUTE
 ON PROCEDURE RECALCINDEXES TO  SYSDBA;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON APPLICATIONS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON CPU TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON EXCEPTIONCLASSES TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON EXCEPTIONMESSAGES TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON METHODNAMES TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON OPTIONS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON OS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON RESULTVALUES TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON SOURCELOCATIONS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON SOURCEUNITS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TESTRESULTS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TESTRUNS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TESTS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TESTSUITES TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON FLAT TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON FLATSORTED TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON LASTFAILURE TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON LASTSUCCESS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON OKRESULTS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON REGRESSIONS TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON REGRESSIONSFLAT TO  SYSDBA WITH GRANT OPTION;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE
 ON TESTSUITESFLAT TO  SYSDBA WITH GRANT OPTION;

