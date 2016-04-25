@ECHO OFF

if not defined PBS_SETLOCAL (
  SETLOCAL
  SET PBS_SETLOCAL=1 )

if "%1"=="" (
  echo ERROR - you must specify a package name
  echo example: %0 PBSmodelling
  goto end )

if "%2"=="" (
	SET arch=64
	) else (
	SET arch=%2
	)

rem build=binary or build=source
if "%3"=="" (
	set build=binary
	) else (
	set build=%3)

SET PBS_NO_PAUSE=1
call RPathCheck.bat %arch%

if not defined PBSERROR (
	rem dir %perlR%\* rem %perlR% defined in Rpaths.bat
	rem %xcopy% /Q /R /Y %perlR%\Rdlists.pm %perlR%\Rdlists.original.pm
	rem sed  "s/aliases>100/aliases>%aliens%/g; s/aliases > 100/aliases>%aliens%/g" %perlR%\Rdlists.pm > %perlR%\Rdlists.new.pm
	rem %xcopy% /Q /R /Y %perlR%\Rdlists.new.pm %perlR%\Rdlists.pm
	if %build%==binary (
		R CMD INSTALL --build --compact-docs --compile-both %1 )
	if %build%==source (
		R CMD build --no-build-vignettes --compact-vignettes %1 )
	rem R CMD INSTALL --build --resave-data --compact-docs %1
	rem R CMD INSTALL --build %1
	rem Rcmd build  --binary %1  ::deprecated
	rem %xcopy% /Q /R /Y %perlR%\Rdlists.original.pm %perlR%\Rdlists.pm
)
:end
set build=
