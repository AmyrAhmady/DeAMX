# DeAMX
DeAMX - .amx files decompiler for SA:MP originally made by trc_ in 2008

----------------------

I am just updating it in my free times.

----------------------

# Features :
- Now it bypasses all anti-deamx method, thanks to [@IllidanS4](https://github.com/IllidanS4)
- Added all SA:MP functions till 0.3.7.
- Added new type of vars. (e.g: PlayerText, Text3D, PlayerText3D and etc..)
- Added all SA:MP callbacks till 0.3.7.
- Fixed the bug with callback parameters and usage of it in callback.
  (e.g: cmdtext should be cmdtext[] as a parameter of callback OnPlayerCommandText or Float:amount in OnPlayer(Take/Give)Damge. )
- Fixed the bug with returning right type of variable.  

----------------------

# To Do:
- Adding some famous includes like streamer, sscanf and etc.


# Usage
```

	DeAMX is a collection of Lua scripts, which means you need
	Lua to run it. If you don't have Lua yet, you can get it for
	free from the official download page:
	  http://luabinaries.sourceforge.net/
	
	Once you have Lua, there are two ways to decompile a script:
	- Place the .lua files and the .bat file in some folder,
	  edit the bat file in a text editor like Notepad, and make
	  sure the path to lua5.1.exe is correct. Save the file and
	  close it.
	  
	  To run, open a command prompt in the folder where you placed
	  deamx, and type:
	  
	    deamx path\to\amxfile.amx
	  
	- Or, place the .lua files in the folder where you installed
	  Lua, open a command prompt in the Lua folder, and type:
	  
	    luaX deamx.lua path\to\amxfile.amx
		
    In both cases, the .amx file will be decompiled and the
	resulting code will be placed in a .pwn file in the same
	directory as the .amx file.
```
