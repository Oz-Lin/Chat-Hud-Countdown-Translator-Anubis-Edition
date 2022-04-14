 /*
 * =============================================================================
 * File:		  Chat_Hud
 * Type:		  Base
 * Description:   Plugin's base file.
 *
 * Copyright (C)   Anubis Edition. All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */
#define PLUGIN_NAME           "Chat_Hud"
#define PLUGIN_AUTHOR         "Anubis"
#define PLUGIN_DESCRIPTION    "Countdown timers based on messages from maps. And translations of map messages."
#define PLUGIN_VERSION        "2.4"
#define PLUGIN_URL            "https://github.com/Stewart-Anubis"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <csgocolors_fix>
#include <SteamWorks>
//#include <json>
#include <smjansson>

#pragma newdecls required

ConVar g_cChatHud = null;
ConVar g_cAvoidSpanking = null;
ConVar g_cAvoidSpankingTime = null;
ConVar g_changecolor = null;
ConVar g_cVHudColor1 = null;
ConVar g_cVHudColor2 = null;
ConVar g_cAutoTranslate = null;
ConVar g_cConsoleChat = null;
ConVar g_cConsoleHud = null;

Handle g_hTimerHandleA = INVALID_HANDLE;
Handle g_hTimerHandleB = INVALID_HANDLE;
Handle g_hHudSyncA = INVALID_HANDLE;
Handle g_hHudSyncB = INVALID_HANDLE;
KeyValues g_hKvChatHud;

Handle g_hChatHud = INVALID_HANDLE;
Handle g_hChatMap = INVALID_HANDLE;
Handle g_hChatSound = INVALID_HANDLE;
Handle g_hHudSound = INVALID_HANDLE;
Handle g_hHudPosition = INVALID_HANDLE;
Handle g_hLineComapare = INVALID_HANDLE;

char g_sPathChatHud[PLATFORM_MAX_PATH];
char g_sClLang[MAXPLAYERS+1][3];
char g_sServerLang[3];
char g_sLineComapare[256];
char g_sConsoleChat[2][64];
char g_sConsoleHud[2][64];
char g_sHudACompare[266];
char g_sHudBCompare[266];

int g_iNumberA;
int g_iNumberB;
int g_iONumberA;
int g_iONumberB;
int g_iHudColor1[3];
int g_iHudColor2[3];
int g_icolor_hudA = 0;
int g_icolor_hudB = 0;
int g_iItemSettings[MAXPLAYERS + 1];

float g_fHudPosA[MAXPLAYERS+1][2];
float g_fHudPosB[MAXPLAYERS+1][2];
float g_fColor_Time;
float g_fAvoidSpankingTime;

bool g_bChatHud;
bool g_bAutoTranslate;
bool g_bAvoidSpanking;
bool g_bIsCountable = false;
bool g_bIsTranlate = false;
bool g_bHudA = false;
bool g_bHudB = false;

enum struct ChatHud_Enum
{
	bool e_bChatHud;
	bool e_bChatMap;
	bool e_bChatSound;
	bool e_bHudSound;
	char e_bHudPosition[64];
}

ChatHud_Enum ChatHudClientEnum[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

	DeleteTimer("All");
	g_hHudSyncA = CreateHudSynchronizer();
	g_hHudSyncB = CreateHudSynchronizer();

	g_hChatHud = RegClientCookie("Chat_Hud", "Chat Hud", CookieAccess_Protected);
	g_hChatMap = RegClientCookie("Chat_Hud_Chat", "Chat Hud Chat", CookieAccess_Protected);
	g_hChatSound = RegClientCookie("Chat_Hud_Chat_Sounds", "Chat Hud Chat Sounds", CookieAccess_Protected);
	g_hHudSound = RegClientCookie("Chat_Hud_Hud_Sounds", "Chat Hud Hud Sounds", CookieAccess_Protected);
	g_hHudPosition = RegClientCookie("Chat_Hud_Position", "Chat Hud Position", CookieAccess_Protected);

	RegConsoleCmd("sm_chud", Command_CHudClient, "Chat Hud Client Menu");

	g_cChatHud = CreateConVar("sm_chat_hud", "1", "Chat Hud Enable = 1/Disable = 0");
	g_cAvoidSpanking = CreateConVar("sm_chat_hud_avoid_spanking", "1", "Map anti spam system, Enable = 1/Disable = 0");
	g_cAvoidSpankingTime = CreateConVar("sm_chat_hud_time_spanking", "2.0", "Map spam detection time");
	g_changecolor = CreateConVar("sm_chat_hud_time_changecolor", "3", "Set the final time for Hud to change colors.");
	g_cVHudColor1 = CreateConVar("sm_chat_hud_color_1", "0 255 0", "RGB color value for the hud Start.");
	g_cVHudColor2 = CreateConVar("sm_chat_hud_color_2", "255 0 0", "RGB color value for the hud Finish.");
	g_cAutoTranslate = CreateConVar("sm_chat_hud_auto_translate", "1", "Chat Hud Auto Translate Enable = 1/Disable = 0");
	g_cConsoleChat = CreateConVar("sm_chat_hud_console_chat", "{red}[Console] {yellow}► {green}TEXT {yellow}◄", "Chat Text format. Do not remove TEXT.");
	g_cConsoleHud = CreateConVar("sm_chat_hud_console_hud", "► TEXT ◄", "Hud Center Text format. Do not remove TEXT.");

	g_cChatHud.AddChangeHook(ConVarChange);
	g_cAvoidSpanking.AddChangeHook(ConVarChange);
	g_cAvoidSpankingTime.AddChangeHook(ConVarChange);
	g_changecolor.AddChangeHook(ConVarChange);
	g_cVHudColor1.AddChangeHook(ConVarChange);
	g_cVHudColor2.AddChangeHook(ConVarChange);
	g_cAutoTranslate.AddChangeHook(ConVarChange);
	g_cConsoleChat.AddChangeHook(ConVarChange);
	g_cConsoleHud.AddChangeHook(ConVarChange);

	g_bChatHud = g_cChatHud.BoolValue;
	g_bAvoidSpanking = g_cAvoidSpanking.BoolValue;
	g_fAvoidSpankingTime = g_cAvoidSpankingTime.FloatValue;
	g_fColor_Time = g_changecolor.FloatValue;
	g_bAutoTranslate = g_cAutoTranslate.BoolValue;
	ChatHudColorRead();
	ChatHudFormatRead();

	AutoExecConfig(true, "Chat_hud");
	
	SetCookieMenuItem(PrefMenu, 0, "Chat Hud");

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}
	GetLanguageInfo(GetServerLanguage(), g_sServerLang, sizeof(g_sServerLang));
}

public void OnMapStart()
{
	LoadTranslations("chat_hud.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	ReadFileChatHud();
}

public void OnMapEnd()
{
	if(g_hKvChatHud) delete g_hKvChatHud;
}

public void OnPluginEnd()
{
	if(g_hKvChatHud) delete g_hKvChatHud;
}

public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen)
{
	if(actions == CookieMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlen, "%T", "Cookie_Menu", client);
	}

	if(actions == CookieMenuAction_SelectOption)
	{
		if(g_bChatHud)
		{
			MenuClientChud(client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	CreateTimer(1.0, OnClientPutInServerPost, client);
}

public Action OnClientPutInServerPost(Handle PutTimer, int client)
{
	if(IsValidClient(client))
	{
		GetLanguageInfo(GetClientLanguage(client), g_sClLang[client], sizeof(g_sClLang[]));
	}
}

public void OnClientCookiesCached(int client)
{
	g_iItemSettings[client] = 0;
	char scookie[64];

	GetClientCookie(client, g_hChatHud, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bChatHud = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bChatHud = true;
		
	GetClientCookie(client, g_hChatMap, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bChatMap = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bChatMap = true;

	GetClientCookie(client, g_hChatSound, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bChatSound = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bChatSound = true;
	
	GetClientCookie(client, g_hHudSound, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bHudSound = view_as<bool>(StringToInt(scookie));
	}
	else	ChatHudClientEnum[client].e_bHudSound = false;
	
	GetClientCookie(client, g_hHudPosition, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		ChatHudClientEnum[client].e_bHudPosition = scookie;
	}
	else	ChatHudClientEnum[client].e_bHudPosition = "-1.0 0.060";

	ChatHudStringPos(client);
}

void ChatHudStringPos(int client)
{
	char StringPos[2][8];

	ExplodeString(ChatHudClientEnum[client].e_bHudPosition, " ", StringPos, sizeof(StringPos), sizeof(StringPos[]));

	g_fHudPosA[client][0] = StringToFloat(StringPos[0]);
	g_fHudPosA[client][1] = StringToFloat(StringPos[1]);
	g_fHudPosB[client][0] = StringToFloat(StringPos[0]);
	float f_temp = StringToFloat(StringPos[1]);
	g_fHudPosB[client][1] = f_temp + 0.025;
}

public void ReadFileChatHud()
{
	if(g_hKvChatHud) delete g_hKvChatHud;
	
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, g_sPathChatHud, sizeof(g_sPathChatHud), "configs/Chat_Hud/%s.txt", mapname);
	
	g_hKvChatHud = new KeyValues("Chat_Hud");
	
	if(!FileExists(g_sPathChatHud)) KeyValuesToFile(g_hKvChatHud, g_sPathChatHud);
	else FileToKeyValues(g_hKvChatHud, g_sPathChatHud);

	KvRewind(g_hKvChatHud);
	CheckSoundsChatHud();
}

void CheckSoundsChatHud()
{
	char s_Buffer[256];
	PrecacheSound("common/talk.wav", false);
	PrecacheSound("common/stuck1.wav", false);
	if(KvGotoFirstSubKey(g_hKvChatHud))
	{
		do
		{
			KvGetString(g_hKvChatHud, "sound", s_Buffer, 64, "default");
			if(!StrEqual(s_Buffer, "default"))
			{
				PrecacheSound(s_Buffer);				
				Format(s_Buffer, sizeof(s_Buffer), "sound/%s", s_Buffer);
				AddFileToDownloadsTable(s_Buffer);
			}
		} while (KvGotoNextKey(g_hKvChatHud));
	}
	KvRewind(g_hKvChatHud);
}

public void ConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if(convar == g_cChatHud) {
		g_bChatHud = g_cChatHud.BoolValue;
	} else if(convar == g_cAvoidSpanking) {
		g_bAvoidSpanking = g_cAvoidSpanking.BoolValue;
	} else if(convar == g_cAvoidSpankingTime) {
		g_fAvoidSpankingTime = g_cAvoidSpankingTime.FloatValue;
	} else if(convar == g_changecolor) {
		g_fColor_Time = g_changecolor.FloatValue;
	} else if(convar == g_cAutoTranslate) {
		g_bAutoTranslate = g_cAutoTranslate.BoolValue;
	} else if(convar == g_cVHudColor1 || convar == g_cVHudColor2) {
		ChatHudColorRead();
	} else if(convar == g_cConsoleChat || convar == g_cConsoleHud) {
		ChatHudFormatRead();
	}
}

public void ChatHudColorRead()
{
	char s_BufferTemp[64];

	g_cVHudColor1.GetString(s_BufferTemp, sizeof(s_BufferTemp));
	ColorStringToArray(s_BufferTemp, g_iHudColor1);

	g_cVHudColor2.GetString(s_BufferTemp, sizeof(s_BufferTemp));
	ColorStringToArray(s_BufferTemp, g_iHudColor2);
}

public void ChatHudFormatRead()
{
	char s_BufferTemp[64];

	g_cConsoleChat.GetString(s_BufferTemp, sizeof(s_BufferTemp));
	FormatStringToArray(s_BufferTemp, g_sConsoleChat);

	g_cConsoleHud.GetString(s_BufferTemp, sizeof(s_BufferTemp));
	FormatStringToArray(s_BufferTemp, g_sConsoleHud);
}

public void ColorStringToArray(const char[] sColorString, int aColor[3])
{
	char asColors[4][4];
	ExplodeString(sColorString, " ", asColors, sizeof(asColors), sizeof(asColors[]));

	aColor[0] = StringToInt(asColors[0]);
	aColor[1] = StringToInt(asColors[1]);
	aColor[2] = StringToInt(asColors[2]);
}

public void FormatStringToArray(const char[] sFormatString, char[][] aFormat)
{
	char asFormat[3][64];
	ExplodeString(sFormatString, "TEXT", asFormat, sizeof(asFormat), sizeof(asFormat[]));

	strcopy(aFormat[0], sizeof(asFormat[]), asFormat[0]);
	strcopy(aFormat[1], sizeof(asFormat[]), asFormat[1]);
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	DeleteTimer("All");
	g_bHudA = false;
	g_bHudB = false;
	g_sLineComapare = "";
	g_sHudACompare = "";
	g_sHudBCompare = "";
}

stock void DeleteTimer(char[] s_TimerHandle = "")
{
	bool b_TimerHandleA = false;
	bool b_TimerHandleB = false;
	bool b_TimerLComapare = false;

	if (StrEqual(s_TimerHandle, "A")) b_TimerHandleA = true;
	if (StrEqual(s_TimerHandle, "B")) b_TimerHandleB = true;
	if (StrEqual(s_TimerHandle, "C")) b_TimerLComapare = true;
	if (StrEqual(s_TimerHandle, "All")) { b_TimerHandleA = true; b_TimerHandleB = true; b_TimerLComapare = true;}

	if(b_TimerHandleA)
	{
		if(g_hTimerHandleA != INVALID_HANDLE)
		{
			KillTimer(g_hTimerHandleA);
		}
		g_hTimerHandleA = INVALID_HANDLE;
		g_icolor_hudB = 0;
		g_sHudACompare = "";
		g_bHudA = false;
	}
	if(b_TimerHandleB)
	{
		if(g_hTimerHandleB != INVALID_HANDLE)
		{
			KillTimer(g_hTimerHandleB);
		}
		g_hTimerHandleB = INVALID_HANDLE;
		g_icolor_hudB = 0;
		g_sHudBCompare = "";
		g_bHudB = false;
	}
	if (b_TimerLComapare)
	{
		if(g_hLineComapare != INVALID_HANDLE)
		{
			KillTimer(g_hLineComapare);
		}
		g_hLineComapare = INVALID_HANDLE;
	}
}

char Blacklist[][] = {
	"recharge", "recast", "cooldown", "cool", "use"
};

bool CheckString(char[] string)
{
	for (int i = 0; i < sizeof(Blacklist); i++)
	{
		if(StrContains(string, Blacklist[i], false) != -1)
		{
			return true;
		}
	}
	return false;
}

public Action SpanReload(Handle sTime)
{
	g_sLineComapare = "";
	g_hLineComapare = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action Command_CHudClient(int client, int arg)
{
	if(IsValidClient(client) && g_bChatHud)
	{
		MenuClientChud(client);
	}
	return Plugin_Handled;
}

void MenuClientChud(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}

	SetGlobalTransTarget(client);
	g_iItemSettings[client] = 0;

	char m_sTitle[256];
	char m_sChatHud[64];
	char m_sChatMap[64];
	char m_sChatSound[64];
	char m_sHudSound[64];
	char m_sHudPosition[64];

	char m_sChatHudTemp[16];
	char m_sChatMapTemp[16];
	char m_sChatSoundTemp[16];
	char m_sHudPositionTemp[16];

	if(ChatHudClientEnum[client].e_bChatHud) Format(m_sChatHudTemp, sizeof(m_sChatHudTemp), "%t", "Enabled");
	else Format(m_sChatHudTemp, sizeof(m_sChatHudTemp), "%t", "Desabled");

	if(ChatHudClientEnum[client].e_bChatMap) Format(m_sChatMapTemp, sizeof(m_sChatMapTemp), "%t", "Enabled");
	else Format(m_sChatMapTemp, sizeof(m_sChatMapTemp), "%t", "Desabled");

	if(ChatHudClientEnum[client].e_bChatSound) Format(m_sChatSoundTemp, sizeof(m_sChatSoundTemp), "%t", "Enabled");
	else Format(m_sChatSoundTemp, sizeof(m_sChatSoundTemp), "%t", "Desabled");

	if(ChatHudClientEnum[client].e_bHudSound) Format(m_sHudPositionTemp, sizeof(m_sHudPositionTemp), "%t", "Enabled");
	else Format(m_sHudPositionTemp, sizeof(m_sHudPositionTemp), "%t", "Desabled");

	Format(m_sTitle, sizeof(m_sTitle),"%t", "Chat Hud Title", m_sChatHudTemp, m_sChatMapTemp, m_sChatSoundTemp, m_sHudPositionTemp, ChatHudClientEnum[client].e_bHudPosition);

	Format(m_sChatHud, sizeof(m_sChatHud), "%t", "Time Counter");
	Format(m_sChatMap, sizeof(m_sChatMap), "%t", "Map Messages");
	Format(m_sChatSound, sizeof(m_sChatSound), "%t", "Chat Click Sound");
	Format(m_sHudSound, sizeof(m_sHudSound), "%t", "Counter Alert Sound");
	Format(m_sHudPosition, sizeof(m_sHudPosition), "%t", "Counter Position");

	Menu MenuCHud = new Menu(MenuClientCHudCallBack);

	MenuCHud.ExitBackButton = true;
	MenuCHud.SetTitle(m_sTitle);

	MenuCHud.AddItem("Time Counter", m_sChatHud);
	MenuCHud.AddItem("Map Messages", m_sChatMap);
	MenuCHud.AddItem("Chat Click Sound", m_sChatSound);
	MenuCHud.AddItem("Counter Alert Sound", m_sHudSound);
	MenuCHud.AddItem("Counter Position", m_sHudPosition);
	MenuCHud.AddItem("", "", ITEMDRAW_NOTEXT);

	MenuCHud.Display(client, MENU_TIME_FOREVER);
}

public int MenuClientCHudCallBack(Handle MenuCHud, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_End)
	{
		delete MenuCHud;
	}

	if (action == MenuAction_Select)
	{
		char sItem[64];
		GetMenuItem(MenuCHud, itemNum, sItem, sizeof(sItem));

		if (StrEqual(sItem[0], "Time Counter"))
		{
			ChatHudClientEnum[client].e_bChatHud = !ChatHudClientEnum[client].e_bChatHud;
			ChatHudCookiesSetBool(client, g_hChatHud, ChatHudClientEnum[client].e_bChatHud);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Map Messages"))
		{
			ChatHudClientEnum[client].e_bChatMap = !ChatHudClientEnum[client].e_bChatMap;
			ChatHudCookiesSetBool(client, g_hChatMap, ChatHudClientEnum[client].e_bChatMap);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Chat Click Sound"))
		{
			ChatHudClientEnum[client].e_bChatSound = !ChatHudClientEnum[client].e_bChatSound;
			ChatHudCookiesSetBool(client, g_hChatSound, ChatHudClientEnum[client].e_bChatSound);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Counter Alert Sound"))
		{
			ChatHudClientEnum[client].e_bHudSound = !ChatHudClientEnum[client].e_bHudSound;
			ChatHudCookiesSetBool(client, g_hHudSound, ChatHudClientEnum[client].e_bHudSound);
			MenuClientChud(client);
		}
		if (StrEqual(sItem[0], "Counter Position"))
		{
			g_iItemSettings[client] = 1;
			CPrintToChat(client, "%t", "Change Hud Position", ChatHudClientEnum[client].e_bHudPosition);
			action = MenuAction_Cancel;
		}
	}

	if (action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack) ShowCookieMenu(client);
	}

	return 0;
}

void ChatHudCookiesSetBool(int client, Handle cookie, bool cookievalue)
{
	char strCookievalue[8];
	BoolToString(cookievalue, strCookievalue, sizeof(strCookievalue));

	SetClientCookie(client, cookie, strCookievalue);
}

void BoolToString(bool value, char[] output, int maxlen)
{
	if(value) strcopy(output, maxlen, "1");
	else strcopy(output, maxlen, "0");
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(client == 0)
	{
		char s_ConsoleChats[256], s_ConsoleChat[256], s_FilterText[sizeof(s_ConsoleChat)+1], s_ChatArray[32][256];
		char s_PrintText[256], s_PrintHud[256], s_Soundp[256], s_Soundt[256], Buffer_Temp[256];
		int i_ConsoleNumber, i_FilterPos;
		

		strcopy(s_ConsoleChats, sizeof(s_ConsoleChats), sArgs);
		StripQuotes(s_ConsoleChats);
		strcopy(s_ConsoleChat, sizeof(s_ConsoleChat), RemoveItens(s_ConsoleChats));

		if (g_bAvoidSpanking && StrEqual(g_sLineComapare, s_ConsoleChat))
		{
			return Plugin_Stop;
		}
		else if(g_bAutoTranslate && g_bIsTranlate)
		{
			return Plugin_Continue;
		}
		else if(!g_hKvChatHud)
		{
			ReadFileChatHud();
			return Plugin_Continue;
		}
		KvRewind(g_hKvChatHud);
		
		Format(g_sLineComapare, sizeof(g_sLineComapare), s_ConsoleChat);

		if (g_hLineComapare != INVALID_HANDLE)
		{
			KillTimer(g_hLineComapare);
			g_hLineComapare = INVALID_HANDLE;
		}
		g_hLineComapare = CreateTimer(g_fAvoidSpankingTime, SpanReload, TIMER_FLAG_NO_MAPCHANGE);

		for (int i = 0; i < sizeof(s_ConsoleChat); i++) 
		{
			if (IsCharAlpha(s_ConsoleChat[i]) || IsCharNumeric(s_ConsoleChat[i]) || IsCharSpace(s_ConsoleChat[i])) 
			{
				s_FilterText[i_FilterPos++] = s_ConsoleChat[i];
			}
		}
		s_FilterText[i_FilterPos] = '\0';
		TrimString(s_FilterText);
		int i_Words = ExplodeString(s_FilterText, " ", s_ChatArray, sizeof(s_ChatArray), sizeof(s_ChatArray[]));

		if(i_Words == 1)
		{
			if(StringToInt(s_ChatArray[0]) != 0)
			{
				g_bIsCountable = true;
				i_ConsoleNumber = StringToInt(s_ChatArray[0]);
			}
		}

		for(int i = 0; i <= i_Words; i++)
		{
			if(StringToInt(s_ChatArray[i]) != 0)
			{
				if(i + 1 <= i_Words && (StrEqual(s_ChatArray[i + 1], "s", false) || (CharEqual(s_ChatArray[i + 1][0], 's') && CharEqual(s_ChatArray[i + 1][1], 'e'))))
				{
					i_ConsoleNumber = StringToInt(s_ChatArray[i]);
					g_bIsCountable = true;
				}
				if(!g_bIsCountable && i + 2 <= i_Words && (StrEqual(s_ChatArray[i + 2], "s", false) || (CharEqual(s_ChatArray[i + 2][0], 's') && CharEqual(s_ChatArray[i + 2][1], 'e'))))
				{
					i_ConsoleNumber = StringToInt(s_ChatArray[i]);
					g_bIsCountable = true;
				}
			}
			if(!g_bIsCountable)
			{
				char c_Word[256];
				strcopy(c_Word, sizeof(c_Word), s_ChatArray[i]);
				int i_Len = strlen(c_Word);

				if(IsCharNumeric(c_Word[0]))
				{
					if(IsCharNumeric(c_Word[1]))
					{
						if(IsCharNumeric(c_Word[2]))
						{
							if(CharEqual(c_Word[3], 's'))
							{
								i_ConsoleNumber = StringEnder(c_Word, 5, i_Len);
								g_bIsCountable = true;
							}
						}
						else if(CharEqual(c_Word[2], 's'))
						{
							i_ConsoleNumber = StringEnder(c_Word, 4, i_Len);
							g_bIsCountable = true;
						}
					}
					else if(CharEqual(c_Word[1], 's'))
					{
						i_ConsoleNumber = StringEnder(c_Word, 3, i_Len);
						g_bIsCountable = true;
					}
				}
			}
			if(g_bIsCountable) break;
		}
		if(!KvJumpToKey(g_hKvChatHud, s_ConsoleChat))
		{
			if(g_bAutoTranslate)
			{
				g_bIsTranlate = true;
				if(strlen(g_sServerLang) == 0) g_sServerLang = "en";
				CreateRequest(s_ConsoleChat, g_sServerLang);
				if(g_bIsCountable && !CheckString(s_ConsoleChat))
				//if(g_bIsCountable)
				{
					Format(s_PrintHud, sizeof(s_PrintHud), "%s%s%s", g_sConsoleHud[0], s_ConsoleChat, g_sConsoleHud[1]);
					InitCountDown(s_PrintHud, i_ConsoleNumber);
				}
				for(int i = 1 ; i < MaxClients; i++)
				{
					if(IsValidClient(i) && ChatHudClientEnum[i].e_bChatMap)
					{
						CPrintToChat(i, "%s%s%s", g_sConsoleChat[0], s_ConsoleChat, g_sConsoleChat[1]);
						if(ChatHudClientEnum[i].e_bChatSound) EmitSoundToClient(i, "common/talk.wav", _, SNDCHAN_AUTO);
					}
				}
				return Plugin_Stop;
			}
			else
			{
				KvJumpToKey(g_hKvChatHud, s_ConsoleChat, true);
				KvSetNum(g_hKvChatHud, "enabled", 1);
				KvSetString(g_hKvChatHud, "default", s_ConsoleChat);
				if(g_bIsCountable) KvSetString(g_hKvChatHud, "ChatHud", s_ConsoleChat);
				KvRewind(g_hKvChatHud);
				KeyValuesToFile(g_hKvChatHud, g_sPathChatHud);
				KvJumpToKey(g_hKvChatHud, s_ConsoleChat);
			}
		}
		if (KvGetNum(g_hKvChatHud, "enabled") <= 0)
		{
			KvRewind(g_hKvChatHud);
			return Plugin_Stop;
		}
		if(!g_bChatHud)
		{
			KvRewind(g_hKvChatHud);
			return Plugin_Continue;
		}
		if(g_bIsCountable && !CheckString(s_ConsoleChat))
		//if(g_bIsCountable)
		{
			KvGetString(g_hKvChatHud, "ChatHud", Buffer_Temp, sizeof(Buffer_Temp), "HUDMISSING");
			if(!StrEqual(Buffer_Temp, "HUDMISSING"))
			{
				Format(s_PrintHud, sizeof(s_PrintHud), "%s%s%s", g_sConsoleHud[0], Buffer_Temp, g_sConsoleHud[1]);
				InitCountDown(s_PrintHud, i_ConsoleNumber);
			}
			g_bIsCountable = false;
		}

		KvGetString(g_hKvChatHud, "sound", s_Soundp, sizeof(s_Soundp), "default");
		
		if(StrEqual(s_Soundp, "default")) Format(s_Soundt, sizeof(s_Soundt), "common/talk.wav");
		else Format(s_Soundt, sizeof(s_Soundt), s_Soundp);

		for(int i = 1 ; i < MaxClients; i++)
		{
			if(IsValidClient(i) && ChatHudClientEnum[i].e_bChatMap)
			{
				KvGetString(g_hKvChatHud, g_sClLang[i], s_PrintText, sizeof(s_PrintText), "LANGMISSING");
				if(StrEqual(s_PrintText, "LANGMISSING")) KvGetString(g_hKvChatHud, "default", s_PrintText, sizeof(s_PrintText), "TEXTMISSING");
				if(!StrEqual(s_PrintText, "TEXTMISSING")) CPrintToChat(i, "%s%s%s", g_sConsoleChat[0], s_PrintText, g_sConsoleChat[1]);
			}
		}
		if(!StrEqual(s_Soundp, "none"))
		{
			for(int i = 1 ; i < MaxClients; i++)
			{
				if(IsValidClient(i) && ChatHudClientEnum[i].e_bChatSound && ChatHudClientEnum[i].e_bChatMap)
				{
					EmitSoundToClient(i, s_Soundt, _, SNDCHAN_AUTO);
				}
			}
		}
		if(KvJumpToKey(g_hKvChatHud, "hinttext"))
		{
			for(int i = 1 ; i < MaxClients; i++)
				if(IsValidClient(i) && ChatHudClientEnum[i].e_bChatHud)
				{
					KvGetString(g_hKvChatHud, g_sClLang[i], s_PrintText, sizeof(s_PrintText), "LANGMISSING");
					if(StrEqual(s_PrintText, "LANGMISSING")) KvGetString(g_hKvChatHud, "default", s_PrintText, sizeof(s_PrintText), "TEXTMISSING");
					if(!StrEqual(s_PrintText, "TEXTMISSING")) PrintHintText(i, "%s%s%s", g_sConsoleHud[0], s_PrintText, g_sConsoleHud[1]);
				}
		}
		KvRewind(g_hKvChatHud);
		return Plugin_Stop;
	}

	if(!IsValidClient(client) || g_iItemSettings[client] == 0)
	{
		return Plugin_Continue;
	}

	char Args[64];
	Format(Args, sizeof(Args), sArgs);
	StripQuotes(Args);

	if(StrEqual(sArgs, "!cancel") || StrContains(command, "say") <= -1 || StrContains(command, "say_team") <= -1)
	{
		CPrintToChat(client, "%t", "Cancel");
		if (g_iItemSettings[client] == 1) MenuClientChud(client);
		g_iItemSettings[client] = 0;
		return Plugin_Stop;
	}
	else if (!g_bChatHud)
	{
		return Plugin_Continue;
	}
	else if (g_iItemSettings[client] == 1)
	{
		ChatHudClientEnum[client].e_bHudPosition = Args;
		g_iItemSettings[client] = 0;
		ChatHudStringPos(client);
		SetClientCookie(client, g_hHudPosition, ChatHudClientEnum[client].e_bHudPosition);
		MenuClientChud(client);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void CreateRequest(char[] input, char[] target)
{

	char s_ConsoleChatsTranslate[256];
	Handle datapack = CreateDataPack();

	Format(s_ConsoleChatsTranslate, sizeof(s_ConsoleChatsTranslate), "%s", input);
	ReplaceString(s_ConsoleChatsTranslate, sizeof(s_ConsoleChatsTranslate), ". ", ".");
	ReplaceString(s_ConsoleChatsTranslate, sizeof(s_ConsoleChatsTranslate), "! ", "!");
	ReplaceString(s_ConsoleChatsTranslate, sizeof(s_ConsoleChatsTranslate), "? ", "?");
	ReplaceString(s_ConsoleChatsTranslate, sizeof(s_ConsoleChatsTranslate), ": ", ":");
	ReplaceString(s_ConsoleChatsTranslate, sizeof(s_ConsoleChatsTranslate), "&", "e");

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "http://translate.googleapis.com/translate_a/single");
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "client", "gtx");
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "dt", "t");	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "sl", "auto");
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "tl", target);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "q", s_ConsoleChatsTranslate);

	WritePackString(datapack, target);
	WritePackString(datapack, input);

	SteamWorks_SetHTTPRequestContextValue(request, datapack);
	SteamWorks_SetHTTPCallbacks(request, Callback_OnHTTPResponse);
	SteamWorks_SendHTTPRequest(request);
}

public int Callback_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, Handle datapack)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{	  
		CloseHandle(datapack);
		g_bIsCountable = false;
		g_bIsTranlate = false;		
		return;
	}

	int iBufferSize;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);

	char[] result = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, result, iBufferSize);
	delete request;
	
	char target[3], input[255], s_Text_Temp[256];
	ResetPack(datapack);
	ReadPackString(datapack, target, 3);
	ReadPackString(datapack, input, 255);
	CloseHandle(datapack);
	
	/* //#include <json>
	JSON_Array arrayA = view_as<JSON_Array>(json_decode(result));
	JSON_Array arrayB = view_as<JSON_Array>(arrayA.GetObject(0));
	JSON_Array arrayC = view_as<JSON_Array>(arrayB.GetObject(0));
	arrayC.GetString(0, s_Text_Temp, sizeof(s_Text_Temp));
	delete arrayA;
	delete arrayB;
	delete arrayC;
	*/ //#include <json>
	
	// #include <smjansson>
	Handle arrayA = json_load(result);

	if(json_is_array(arrayA))
	{
		Handle arrayB = json_array_get(arrayA, 0);
		Handle arrayC = json_array_get(arrayB, 0);
		json_array_get_string(arrayC, 0, s_Text_Temp, sizeof(s_Text_Temp));
		delete arrayB;
		delete arrayC;
	}
	else
	{
		delete arrayA;
		g_bIsCountable = false;
		g_bIsTranlate = false;
		return;
	}
	
	delete arrayA;
	// #include <smjansson>
	
	if(strlen(s_Text_Temp) != 0)
	{
		KvRewind(g_hKvChatHud);
		KvJumpToKey(g_hKvChatHud, input, true);
		KvSetNum(g_hKvChatHud, "enabled", 1);
		KvSetString(g_hKvChatHud, "default", input);
		KvSetString(g_hKvChatHud, target, s_Text_Temp);
		if(g_bIsCountable) KvSetString(g_hKvChatHud, "ChatHud", s_Text_Temp);
		KvRewind(g_hKvChatHud);
		KeyValuesToFile(g_hKvChatHud, g_sPathChatHud);
		KvRewind(g_hKvChatHud);
	}
	g_bIsCountable = false;
	g_bIsTranlate = false;
}

public bool CharEqual(int a, int b)
{
	if(a == b || a == CharToLower(b) || a == CharToUpper(b))
	{
		return true;
	}
	return false;
}

public int StringEnder(char[] a, int b, int c)
{
	if(CharEqual(a[b], 'c'))
	{
		a[c - 3] = '\0';
	}
	else
	{
		a[c - 1] = '\0';
	}
	return StringToInt(a);
}

public void InitCountDown(char[] sText, int i_Number)
{
	if (!g_bHudA)
	{
		char sANumber[8];
		IntToString(i_Number, sANumber, sizeof(sANumber));
		strcopy(g_sHudACompare, sizeof(g_sHudACompare), sText);
		ReplaceString(g_sHudACompare, sizeof(g_sHudACompare), sANumber, "");

		if(g_bAvoidSpanking && strlen(g_sHudACompare) != 0 && StrEqual(g_sHudACompare, g_sHudBCompare, false))
		{
			g_sHudACompare = "";
			return;
		}
		g_bHudA = true;
		g_bHudB = false;
		
		g_iNumberA = i_Number;
		g_iONumberA = i_Number;

		if(g_hTimerHandleA != INVALID_HANDLE)
		{
			KillTimer(g_hTimerHandleA);
			g_hTimerHandleA = INVALID_HANDLE;
		}

		DataPack TimerPackA;
		g_hTimerHandleA = CreateDataTimer(1.0, RepeatMSGA, TimerPackA, TIMER_REPEAT);
		TimerPackA.WriteString(sText);

		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				SendHudMsgA(i, sText);
			}
		}
	}
	else if (!g_bHudB)
	{
		char sBNumber[8];
		IntToString(i_Number, sBNumber, sizeof(sBNumber));
		strcopy(g_sHudBCompare, sizeof(g_sHudBCompare), sText);
		ReplaceString(g_sHudBCompare, sizeof(g_sHudBCompare), sBNumber, "");

		if(g_bAvoidSpanking && strlen(g_sHudBCompare) != 0 && StrEqual(g_sHudBCompare, g_sHudACompare, false))
		{
			g_sHudBCompare = "";
			return;
		}
		g_bHudA = false;
		g_bHudB = true;
		g_iNumberB = i_Number;
		g_iONumberB = i_Number;

		if(g_hTimerHandleB != INVALID_HANDLE)
		{
			KillTimer(g_hTimerHandleB);
			g_hTimerHandleB = INVALID_HANDLE;
		}

		DataPack TimerPackB;
		g_hTimerHandleB = CreateDataTimer(1.0, RepeatMSGB, TimerPackB, TIMER_REPEAT);
		TimerPackB.WriteString(sText);

		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				SendHudMsgB(i, sText);
			}
		}
	}
}

public Action RepeatMSGA(Handle timer, Handle h_PackA)
{
	g_iNumberA--;
	if(g_iNumberA <= 0)
	{
		DeleteTimer("A");
		g_icolor_hudA = 0;
		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				ClearSyncHud(i, g_hHudSyncA);
				if(ChatHudClientEnum[i].e_bChatHud && ChatHudClientEnum[i].e_bHudSound)
				{
					EmitSoundToClient(i, "common/stuck1.wav", _, SNDCHAN_AUTO, SNDLEVEL_LIBRARY);
				}
			}
		}
		g_sHudACompare = "";
		return Plugin_Handled;
	}

	char string[266], sNumber[8], sONumber[8];
	ResetPack(h_PackA);
	ReadPackString(h_PackA, string, sizeof(string));

	IntToString(g_iONumberA, sONumber, sizeof(sONumber));
	IntToString(g_iNumberA, sNumber, sizeof(sNumber));

	ReplaceString(string, sizeof(string), sONumber, sNumber);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			SendHudMsgA(i, string);
		}
	}
	return Plugin_Handled;
}

public Action RepeatMSGB(Handle timer, Handle h_PackB)
{
	g_iNumberB--;
	if(g_iNumberB <= 0)
	{
		DeleteTimer("B");
		g_icolor_hudB = 0;
		for (int i = 1; i <= MAXPLAYERS + 1; i++)
		{
			if(IsValidClient(i))
			{
				ClearSyncHud(i, g_hHudSyncB);
				if(ChatHudClientEnum[i].e_bChatHud && ChatHudClientEnum[i].e_bHudSound)
				{
					EmitSoundToClient(i, "common/stuck1.wav", _, SNDCHAN_AUTO, SNDLEVEL_LIBRARY);
				}
			}
		}
		g_sHudBCompare = "";
		return Plugin_Handled;
	}

	char string[266], sNumber[8], sONumber[8];
	ResetPack(h_PackB);
	ReadPackString(h_PackB, string, sizeof(string));

	IntToString(g_iONumberB, sONumber, sizeof(sONumber));
	IntToString(g_iNumberB, sNumber, sizeof(sNumber));

	ReplaceString(string, sizeof(string), sONumber, sNumber);

	for (int i = 1; i <= MAXPLAYERS + 1; i++)
	{
		if(IsValidClient(i))
		{
			SendHudMsgB(i, string);
		}
	}
	return Plugin_Handled;
}

public void SendHudMsgA(int client, char[] szMessage)
{
	if (ChatHudClientEnum[client].e_bChatHud)
	{
		if(g_icolor_hudA == 0 && g_iNumberA > g_fColor_Time) SetHudTextParams(g_fHudPosA[client][0], g_fHudPosA[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 2, 0.1, 0.02, 0.1);
		if(g_icolor_hudA >= 1 && g_iNumberA > g_fColor_Time) SetHudTextParams(g_fHudPosA[client][0], g_fHudPosA[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 0, 0.0, 0.0, 0.0);
		if(g_icolor_hudA > 0  && g_iNumberA <= g_fColor_Time) SetHudTextParams(g_fHudPosA[client][0], g_fHudPosA[client][1], 1.0, g_iHudColor2[0], g_iHudColor2[1], g_iHudColor2[2], 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSyncA, szMessage);
	}

	g_icolor_hudA++;
}

public void SendHudMsgB(int client, char[] szMessage)
{
	if (ChatHudClientEnum[client].e_bChatHud)
	{
		if(g_icolor_hudB == 0 && g_iNumberB > g_fColor_Time) SetHudTextParams(g_fHudPosB[client][0], g_fHudPosB[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 2, 0.2, 0.01, 0.1);
		if(g_icolor_hudB >= 1 && g_iNumberB > g_fColor_Time) SetHudTextParams(g_fHudPosB[client][0], g_fHudPosB[client][1], 1.0, g_iHudColor1[0], g_iHudColor1[1], g_iHudColor1[2], 255, 0, 0.0, 0.0, 0.0);
		if(g_icolor_hudB > 0  && g_iNumberB <= g_fColor_Time) SetHudTextParams(g_fHudPosB[client][0], g_fHudPosB[client][1], 1.0, g_iHudColor2[0], g_iHudColor2[1], g_iHudColor2[2], 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSyncB, szMessage);
	}
	g_icolor_hudB++;
}

stock bool IsValidClient(int client, bool bzrAllowBots = false, bool bzrAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bzrAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bzrAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}

stock char RemoveItens(const char[] s_Format, any...)
{
	char s_Text[256];
	//VFormat(s_Text, sizeof(s_Text), s_Format, 2);
	strcopy(s_Text, sizeof(s_Text), s_Format);
	/* Removes itens */
	char s_RemoveItens[][] = {"%", "$", "#", ">", "<", "*", "-", "_", "=", "+", "-", "|", "@", "/", "="};
	for(int i_Itens = 0; i_Itens < sizeof(s_RemoveItens); i_Itens++ ) {
		ReplaceString(s_Text, sizeof(s_Text), s_RemoveItens[i_Itens], "", false);
	}
	TrimString(s_Text);
	return s_Text;
}