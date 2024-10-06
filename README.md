 ====================   PATH KILLER   =====================
|                           ---                            |
|   Kill any process located into specified folder paths   |

--------------------

**How to preformat folders list inside the script if you don't want give /folder arguments :**
```
set "folders="C:\first\path";"C:\second path";"C:\third\path""
```

--------------------

### Optionnal : call with args to replace the default config below

**Here is supported args**:
```
/folder  "C:\give\a\path"        : A folder to kill processes from. You can use this argument may times
/logfile "%temp%\pathkiller.log" : Logs location
/logs               1 (or 0)     : Enable logs
/recursive          1 (or 0)     : Enable recursive search into subfolders
/checkonly          0 (or 1)     : Not kill + show return code + pause
/test               0 (or 1)     : Kill + show return code + pause
/disablereturncodes 0 (or 1)     : Activate if you want to return 0 everytime
/silent             0 (or 1)     : Hide text output from taskkill commands
/verysilent         0 (or 1)     : Hide everything
                    |     |
         Default <--'     '--> You can replace in the file / or give argument to replace
```

**How to call with args** : 
```
pathkiller.bat /folder "C:\first\path" /folder "C:\second path" /test 1
```

**How to call properly from another batch** : 
```
call pathkiller.bat /folder "C:\Program Files\Mozilla" ^
                    /folder "%programfiles%\Google\Chrome" ^
                    /recursive 1 ^
                    /checkonly 0 ^
                    /test 1 ^
                    /disablereturncodes 1 ^
                    /silent 0 ^
                    /logs 1 ^
                    /logfile "C:\Windows\Temp"
```

--------------------

Return codes
```
0 = Some processes have been found and killed
1 = Not any process to kill was found
2 = %folders% value is null (check if your args are correctly given, otherwise if default is correctly set)
3 = No valid filter created (check if your args are correctly given)
4 = Failed to close those processes
5 = Unrecognized argument
```

--------------------

**Remember :**
- %temp% from user/admin     = %localappdata%\Temp
- %temp% from system account = %windir%\Temp
