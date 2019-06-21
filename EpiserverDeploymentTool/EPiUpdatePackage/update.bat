@echo off  
 if '%1' ==''  (
 echo  USAGE: %0  web application path "[..\episerversitepath or c:\episerversitepath]" 
	) else (
epideploy.exe  -a sql -s "%~f1"  -p "EPiServer.CMS.Core.10.9.2\epiupdates\*"  -m "1800"  -c "EPiServerDB"
epideploy.exe  -a sql -s "%~f1"  -p "EPiServer.Find.Cms.12.5.1\epiupdates\*"  -m "1800"  -c "EPiServerDB"
) 

