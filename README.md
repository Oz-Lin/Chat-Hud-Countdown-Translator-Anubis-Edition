# [ANY] Chat_Hud_Countdown_translator

* Compiled in version; SourceMod Version: 1.10.0.6492
* Sorry for my English.

* Author Anubis.
* Version = 2.4

### Countdown HUD on the screen, with 2 Lines!
With the possibility of altering and translating the messages of the Map.
File addons\sourcemod\configs\Chat_Hud\mapname.txt
automatically generated !!

### New

* Client menu.
* Alert sound when resetting the scanner.
* Client preferences.
* Still in testing , but it uses the google API to generate the translations of the map in the server language .
* Created cvar with central color system - Requires deleting colors from translation files for anyone to update or delete the file.
* Improved repeated message detection system.
* Translation fix.

### Requires

* SMJansson - https://github.com/thraaawn/SMJansson
* SteamWorks - https://github.com/KyleSanderson/SteamWorks

### Server ConVars

* sm_chat_hud - Chat Hud Enable = 1/Disable = 0
* sm_chat_hud_avoid_spanking - Map anti spam system, Enable = 1/Disable = 0
* sm_chat_hud_time_spanking - Map spam detection time
* sm_chat_hud_time_changecolor - Set the final time for Hud to change colors.
* sm_chat_hud_color_1 - RGB color value for the hud Start.
* sm_chat_hud_color_2 - RGB color value for the hud Finish.
* sm_chat_hud_auto_translate - Chat Hud Auto Translate Enable = 1/Disable = 0
* sm_chat_hud_console_chat - Chat Text format. Do not remove TEXT.
* sm_chat_hud_console_hud - Hud Center Text format. Do not remove TEXT.

### Commands

* sm_chud - Client Preferences

### Credits

* AntiTeal - countdownhud
* Franc1sco franug - franug_consolechatmanager

![alt text](https://raw.githubusercontent.com/Stewart-Anubis/Chat-Hud-Countdown-Translator-Anubis-Edition/main/img/1.jpg)
