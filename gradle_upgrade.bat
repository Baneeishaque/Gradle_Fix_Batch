@echo off
setlocal EnableDelayedExpansion
SET apk=%~1
IF "%apk%"=="" (
	SET mode=own
) ELSE SET mode=CMD
::echo %mode%
::pause
IF "%mode%"=="CMD" (GOTO process_CMD) ELSE GOTO process_own
GOTO EOF

:process_own
ECHO. | tee gradle_upgrade-results.txt
GOTO sdk-tools
ECHO Fixing Android Gradle Plugin | tee -a gradle_upgrade-results.txt
sed s/com.android.tools.build:gradle:.*/com.android.tools.build:gradle:3.0.0-alpha5'/g build.gradle >build-new.gradle
>nul find "google()" build.gradle && (
  GOTO process_without_google_repository
) || (
  GOTO process
)

:process
ECHO Fixing Google Repository | tee -a gradle_upgrade-results.txt
sed "1,/repositories {/{x;/first/s///;x;s/repositories {/repositories {\n\t\tgoogle()/;}" build-new.gradle >build-new-out.gradle
del build-new.gradle
ECHO Current Gradle Build File | tee -a gradle_upgrade-results.txt
cat build.gradle | tee -a gradle_upgrade-results.txt
del build.gradle
rename build-new-out.gradle build.gradle
ECHO Modified Gradle Build File | tee -a gradle_upgrade-results.txt
cat build.gradle | tee -a gradle_upgrade-results.txt
GOTO wrapper-process

:process_without_google_repository
ECHO Current Gradle Build File | tee -a gradle_upgrade-results.txt
cat build.gradle | tee -a gradle_upgrade-results.txt
del build.gradle
rename build-new.gradle build.gradle
ECHO Modified Gradle Build File | tee -a gradle_upgrade-results.txt
cat build.gradle | tee -a gradle_upgrade-results.txt

:wrapper-process
ECHO Fixing Gradle Wrapper File | tee -a gradle_upgrade-results.txt
sed s/gradle-.*/gradle-4.1-milestone-1-all.zip/g gradle/wrapper/gradle-wrapper.properties >gradle/wrapper/gradle-wrapper-new.properties
CD gradle/wrapper
ECHO Current Gradle Wrapper File | tee -a gradle_upgrade-results.txt
cat gradle-wrapper.properties | tee -a gradle_upgrade-results.txt
del gradle-wrapper.properties
rename gradle-wrapper-new.properties gradle-wrapper.properties
ECHO.   
ECHO.   
ECHO Modified Gradle Wrapper File | tee -a gradle_upgrade-results.txt
cat gradle-wrapper.properties | tee -a gradle_upgrade-results.txt
CD ..
CD ..

:sdk-tools
DIR /s /b | findstr "build.gradle" >project-files.list
for /f "tokens=* delims=" %%x in (project-files.list) do (
	ECHO Gradle Build File : %%x | tee -a gradle_upgrade-results.txt
	findstr compileSdkVersion %%x | tee -a gradle_upgrade-results.txt
	findstr buildToolsVersion %%x | tee -a gradle_upgrade-results.txt
)
GOTO EOF

:process_CMD
ECHO.
::GOTO sdk-tools_CMD
ECHO Fixing Android Gradle Plugin
sed s/com.android.tools.build:gradle:.*/com.android.tools.build:gradle:3.0.0-alpha5'/g build.gradle >build-new.gradle
>nul find "google()" build.gradle && (
  GOTO process_without_google_repository_CMD
) || (
  GOTO upgrade_process_CMD
)

:upgrade_process_CMD
ECHO Fixing Google Repository
sed "1,/repositories {/{x;/first/s///;x;s/repositories {/repositories {\n\t\tgoogle()/;}" build-new.gradle >build-new-out.gradle
del build-new.gradle
ECHO Current Gradle Build File
cat build.gradle
del build.gradle
rename build-new-out.gradle build.gradle
ECHO Modified Gradle Build File
cat build.gradle
GOTO wrapper-process

:process_without_google_repository_CMD
ECHO Current Gradle Build File
cat build.gradle
del build.gradle
rename build-new.gradle build.gradle
ECHO Modified Gradle Build File
cat build.gradle

:wrapper-process
ECHO Fixing Gradle Wrapper File
sed s/gradle-.*/gradle-4.1-milestone-1-all.zip/g gradle/wrapper/gradle-wrapper.properties >gradle/wrapper/gradle-wrapper-new.properties
CD gradle/wrapper
ECHO Current Gradle Wrapper File
cat gradle-wrapper.properties
del gradle-wrapper.properties
rename gradle-wrapper-new.properties gradle-wrapper.properties
ECHO.   
ECHO.   
ECHO Modified Gradle Wrapper File
cat gradle-wrapper.properties
CD ..
CD ..

:sdk-tools_CMD
DIR /s /b | findstr "build.gradle" >project-files.list
SET VAR=before
for /f "tokens=* delims=" %%x in (project-files.list) do (

	if !VAR! EQU before (
		ECHO Project Gradle Build File : %%x
		>nul findstr "compileSdkVersion = " "%%x" && (
			SET build_file=%%x
			GOTO fix_project_sdk
			::findstr /c:"compileSdkVersion = " "%%x" 
			::findstr /c:"buildToolsVersion = " "%%x" 
		)
		
	) ELSE (
		ECHO Module Gradle Build File : %%x	
		SET build_file=%%x
		GOTO fix_app_sdk
		::findstr /c:"compileSdkVersion" "%%x" 
		::findstr /c:"buildToolsVersion" "%%x" 		
	)
	
	SET VAR=after
)

SET VAR=before
for /f "tokens=* delims=" %%x in (project-files.list) do (

	if !VAR! EQU before (
		ECHO Project Gradle Build File : %%x
		>nul findstr "targetSdk = " "%%x" && (
			SET build_file=%%x
			GOTO fix_project_sdk2
			::findstr /c:"targetSdk = " "%%x" 
			::findstr /c:"buildTools = " "%%x" 
		)
		
	) 
	
	SET VAR=after
)

DIR /s /b | findstr "gradle.properties" >project-files.list
SET VAR=before
for /f "tokens=* delims=" %%x in (project-files.list) do (

	if !VAR! EQU before (
		ECHO Project Gradle Properties File : %%x
		>nul findstr "TARGET_SDK_VERSION=" "%%x" && (
			SET build_file=%%x
			GOTO fix_project_properties
			::findstr /c:"TARGET_SDK_VERSION=" "%%x" 
			::findstr /c:"BUILD_TOOLS_VERSION=" "%%x" 
		)
		
	) 
	
	SET VAR=after
)

SET VAR=before
for /f "tokens=* delims=" %%x in (project-files.list) do (

	if !VAR! EQU before (
		ECHO Project Gradle Properties File : %%x
		>nul findstr "ANDROID_BUILD_SDK_VERSION=" "%%x" && (
			SET build_file=%%x
			GOTO fix_project_properties2
			::findstr /c:"ANDROID_BUILD_SDK_VERSION=" "%%x" 
			::findstr /c:"ANDROID_BUILD_TOOLS_VERSION=" "%%x" 
		)
		
	) 
	
	SET VAR=after
)

GOTO EOF

:fix_project_sdk
ECHO Fixing Project Build Gradle File
sed "s/compileSdkVersion =.*/compileSdkVersion = 26/g" "%build_file%" | sed "s/buildToolsVersion =.*/buildToolsVersion = \"26.0.0\"/g" >build-new.gradle
ECHO Current Gradle Build File
cat build.gradle
del build.gradle
rename build-new.gradle build.gradle
ECHO Modified Gradle Build File
cat build.gradle
GOTO EOF

:fix_app_sdk
ECHO Fixing Application Build Gradle File
CALL Fix_app_sdk %build_file%
CD ..
GOTO EOF

:fix_project_sdk2
ECHO Fixing Project Build Gradle File
sed "s/targetSdk = .*/targetSdk = 26/g" "%build_file%" | sed "s/buildTools = .*/buildTools = \"26.0.0\"/g" >build-new.gradle
ECHO Current Gradle Build File
cat build.gradle
del build.gradle
rename build-new.gradle build.gradle
ECHO Modified Gradle Build File
cat build.gradle
GOTO EOF

:fix_project_properties
ECHO Fixing Project Properties File
sed "s/TARGET_SDK_VERSION=.*/TARGET_SDK_VERSION=26/g" "%build_file%" | sed "s/BUILD_TOOLS_VERSION=.*/BUILD_TOOLS_VERSION=26.0.0/g" >gradle-new.properties
ECHO Current Gradle Properties File
cat gradle.properties
del gradle.properties
rename gradle-new.properties gradle.properties
ECHO Modified Gradle Properties File
cat gradle.properties
GOTO EOF

:fix_project_properties2
ECHO Fixing Project Properties File
sed "s/ANDROID_BUILD_SDK_VERSION=.*/ANDROID_BUILD_SDK_VERSION=26/g" "%build_file%" | sed "s/ANDROID_BUILD_TOOLS_VERSION=.*/ANDROID_BUILD_TOOLS_VERSION=26.0.0/g" >gradle-new.properties
ECHO Current Gradle Properties File
cat gradle.properties
del gradle.properties
rename gradle-new.properties gradle.properties
ECHO Modified Gradle Properties File
cat gradle.properties

:EOF