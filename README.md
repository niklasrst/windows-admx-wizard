# 🪄 ADMX Wizard 🪄

This tool can be used to create a custom ADMX and ADML file which creates or modifies keys in the Windows Registry.

## How to?

If you want to use this tool you need to:

1.  Add Registry Keys into `add-keys.csv`:

``` csv
path,type,name,value
HKEY_LOCAL_MACHINE\SOFTWARE\NIKLASRAST,STRING,Test String,SomeValue
HKEY_CURRENT_USER\SOFTWARE\NIKLASRAST,DWORD,Test DWORD,1
```

The csv file has fields for `path`,`type`,`name` and `value`. Fill them like this example:

_STRING Key:_
- path: HKEY_LOCAL_MACHINE\SOFTWARE\NIKLASRAST
- type: STRING
- name: Test String
- value: SomeValue

_DWORD Key:_
- path: HKEY_LOCAL_MACHINE\SOFTWARE\NIKLASRAST
- type: DWORD
- name: Test DWORD
- value: 1

_BINARY Key:_
- path: HKEY_LOCAL_MACHINE\SOFTWARE\NIKLASRAST
- type: BINARY
- name: Test BINARY
- value: 0100000000200000020000000F024E0000000000

You can add as many keys as you need - one per line.

2. Run the `New-ADMXADML.ps1` script:

``` powershell
.\New-ADMXADML.ps1 -Name "SetTheFileName" -CSVPath "Path/To/add-keys.csv"
```

This will do the following:
 - Check if the `add-keys.csv` exists in the same directory as the script. If not it will create a template csv file which you can use to add registry keys.
 - Create GUIDs which are internally used for the admx template.
 - Ask you for the name of the admx/adml files.
 - Add all registry keys that are defined inside of `add-keys.csv` into the created admx/adml files. Each key will also be logged on the console. If all messages are green then everything is OK. If you see a red line there was an issue.

 3. Deploy the admx/adml file
Once the files have been created you simply need to upload them to Intune as a [Imported ADMX](https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/DevicesWindowsMenu/~/configProfiles). Afterwards you can use them in a new configuration profile from the `Imported Administrative templates (Preview)` type.


## 🤝 Contributing

Before making your first contribution please see the following guidelines:
1. [Semantic Commit Messages](https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716)
1. [Git Tutorials](https://www.youtube.com/playlist?list=PLu-nSsOS6FRIg52MWrd7C_qSnQp3ZoHwW)
1. [Create a PR from a pushed branch](https://learn.microsoft.com/en-us/azure/devops/repos/git/pull-requests?view=azure-devops&tabs=browser#from-a-pushed-branch)

---

Made with ❤️ by [Niklas Rast](https://github.com/niklasrst)
