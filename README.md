 ====================   PATH KILLER   =====================
|                           ---                            |
|   Kill any process located into specified folder paths   |

--------------------

**How to preformat folders list inside the script if you don't want give /folder arguments :**
```
set "folders="C:\first\path";"C:\second path";"C:\third\path""
```
Be careful if you provide any /folder arguments, the first one will reset this variable %folders%

--------------------

### Optionnal : call with args to replace the default config below

**Here is supported args**:
```
/folder  "C:\give\a\path"        : A folder to kill processes from. **You can use this argument many times**
/logpath "%temp%\pathkiller.log" : Log file location

/logs               1 (or 0)     : Enable logs
/recursive          1 (or 0)     : Enable recursive search into subfolders
/retry              1 (or 0)     : Kill again if processes still runing (max 3 attemps, 2s loop)
/checkonly          0 (or 1)     : Not kill + show return code + pause
/endpause           0 (or 1)     : Pause at the end
/disablereturncodes 0 (or 1)     : Activate if you want to return 0 everytime
/silent             0 (or 1)     : Hide text output from taskkill commands
/verysilent         0 (or 1)     : Hide everything
                    |     |
         Default <--'     '--> You can replace in the file / or give corresponding argument to replace
```

**How to call with args** : 
```
pathkiller.bat /folder "C:\first\path" /folder "C:\second path" /endpause 1
```

**How to call properly with all arguments from another batch** : 
```
call pathkiller.bat /folder "C:\Program Files\Mozilla" ^
                    /folder "%programfiles%\Google\Chrome" ^
                    /logpath "%temp%\pathkiller.log"
                    /logs 1 ^
                    /recursive 1 ^
                    /retry 1 ^
                    /checkonly 0 ^
                    /endpause 0 ^
                    /disablereturncodes 0 ^
                    /silent 0 ^
```

--------------------

Return codes
```
0 = Some processes have been found (if checkonly=1) or killed (if checkonly=0)
1 = Not any process to kill was found
2 = %folders% value is null (check if your args are correctly given, otherwise if default is correctly set)
3 = No valid filter created (check if your args are correctly given)
4 = Failed to close some processes
5 = Unrecognized argument
```

--------------------

**Remember :**
- %temp% from user/admin     = %localappdata%\Temp
- %temp% from system account = %windir%\Temp
