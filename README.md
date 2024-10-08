 ## **PATH KILLER**



Description
|                           ---                            |
|                                                       |
|   **Kill any processeS by path, title or name**   |
|                                                       |
|   Optionnal : call with arguments to replace the default config   |

--------------------

Opening this script without any arg : full default configuration applied, you have to complete at least **%folders%** or **%titles%** or **%processes%** inside the script

**How to preformat folders, titles and processes lists inside the script if you don't want to give arguments :**
```
set "folders="C:\first\path";"C:\second path";"C:\third\path""
set "titles="first title";"second title""
set "processes="anyprocess.exe";"second_process.exe""
```

--------------------

- If you provide any /folder  arguments, the first one will reset the variable %folders%
- If you provide any /title   arguments, the first one will reset the variable %titles%
- If you provide any /process arguments, the first one will reset the variable %processes%

**Supported arguments**:
```
/folder  "C:\give\a\path"        : Folder to kill processes from. Usable many times
/title   "this window title"     : Title of windows to kill. Usable many times
/process "anyprocess.exe"        : Process name you want to kill. Usable many times

/logpath "%temp%\pathkiller.log" : Log file location
/titleim "anyprocess.exe"        : If defined %titles%, filter by process name - eg : cmd.exe

/titlepartial       1 (or 0)     : Search partial title and case unsensitive - 0 mean exact title
/logs               1 (or 0)     : Enable logs
/recursive          1 (or 0)     : If %folders% defined, search into subfolders
/retry              1 (or 0)     : Kill again if processes still runing (max 4 attemps, 1s loop)
/checkonly          0 (or 1)     : Only search without killing
/endpause           0 (or 1)     : Pause script at the end to let you read
/disablereturncodes 0 (or 1)     : Final return code '0' everytime
/silent             0 (or 1)     : Hide text output from taskkill commands
/verysilent         0 (or 1)     : Hide everything
                    |     |
         Default <--'     '--> You can replace in the file OR give corresponding argument (override)
```

**How to call with args** : 
```
pathkiller.bat /folder "C:\first\path" /folder "C:\second path" /endpause 1
```

**How to call properly with all arguments from another batch** : 

In this case make sure %CD% is already in pathkiller.bat directory to let cmd interpret arguments correctly.
Do not use full path of pathkiller.bat if it contains spaces or parenthesis.
```
cmd /c pathkiller.bat ^
       /folder "C:\Program Files\Mozilla" ^
       /folder "%programfiles%\Google\Chrome" ^
       /recursive 1 ^
       /process "notepad++.exe" ^
       /process "chrome.exe" ^
       /title "first window title" ^
       /title "second window title" ^
       /titleim "cmd.exe" ^
       /titlepartial 1 ^
       /retry 1 ^
       /checkonly 0 ^
       /endpause 1 ^
       /disablereturncodes 0 ^
       /silent 0
```

--------------------

**Return codes**
```
0 = Some processes have been found (if checkonly=1) or killed (if checkonly=0)
1 = Not any process to kill was found
2 = Variables %folders%, %titles% and %processes% are all empty
3 = No valid filter created (related to %folders% - maybe check arguments synthax)
4 = Failed to close some processes
5 = Argument not recognized
```

--------------------

**Remember :**
```
User/Admin %temp%     = %localappdata%\Temp
System account %temp% = %windir%\Temp  OR  %windir%\System32\config\systemprofile\AppData\Local\Temp
```
