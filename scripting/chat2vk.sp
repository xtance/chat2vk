#include <sourcemod>
#include <cstrike>
#include <colorvariables>
#include <SteamWorks>
#include <sourcecomms>
#include <autoexecconfig>

ConVar g_sourcecomms;
ConVar g_token;
ConVar g_msgPerRound;
int iVK[MAXPLAYERS + 1];
int iMsgPerRound;
char szToken[128];

public Plugin myinfo =
{
	name = "Chat 2 VK",
	author = "XTANCE",
	description = "Send messages to VK conversation",
	version = "1",
	url = "https://t.me/xtance"
};

public OnPluginStart()
{
	AutoExecConfig_SetFile("chat2vk", "sourcemod");
	AutoExecConfig_SetCreateFile(true);
	g_sourcecomms = AutoExecConfig_CreateConVar("g_sourcecomms", "1", "SourceComms Support : 1=ON, 0=OFF");
	g_token = AutoExecConfig_CreateConVar("g_token", "thisisyourtoken", "Токен от группы VK. Подробнее : https://pastebin.com/YQ2dwGWY");
	g_msgPerRound = AutoExecConfig_CreateConVar("g_msgPerRound", "3", "Сколько сообщений в раунд можно отправить.");
	AutoExecConfig_ExecuteFile();
	RegConsoleCmd("sm_vk", VKsay, "Send a message to VK conversation");
}

public OnConfigsExecuted()
{
	g_token.GetString(szToken, 128);
	iMsgPerRound = g_msgPerRound.IntValue;
}

public HookPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerAlive(iClient) && IsClientInGame(iClient))
	{
		iVK[iClient] = 0;
	}
}

public Action VKsay(int iClient, int iArgs)
{
	char szText[256];
	if(iArgs < 1)
	{
		CPrintToChat(iClient,"{green}>>{default} Нельзя послать пустое сообщение!");
		return Plugin_Handled;
	}
	
	GetCmdArgString(szText, sizeof(szText));
	
	//Проверка SourceComms
	if (g_sourcecomms.BoolValue)
	{
		if (SourceComms_GetClientGagType(iClient) == bNot)
		{
			if (iVK[iClient] < iMsgPerRound)
			{
				char szURL[1024];
				char szSteam[32];
				GetClientAuthId(iClient, AuthId_Steam2, szSteam, sizeof(szSteam), true);
				FormatEx(szURL, sizeof(szURL), "https://api.vk.com/method/messages.send?chat_id=1&message=Игрок \"%N\" (%s) пишет :NEWLINE NEWLINE%s&v=5.80&access_token=%s",iClient,szSteam,szText,szToken);
				//Костыль :
				ReplaceString(szURL, sizeof(szURL), " ", "%20", false);
				ReplaceString(szURL, sizeof(szURL), "NEWLINE", "%0A", false);
				//Дебаг :
				//PrintToConsole(iClient,szURL);
				Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, szURL);
				SteamWorks_SetHTTPCallbacks(req, OnRequestComplete);
				SteamWorks_SetHTTPRequestHeaderValue(req, "User-Agent", "Test");
				SteamWorks_SendHTTPRequest(req);
				iVK[iClient]++;
				CPrintToChat(iClient, "{yellow}>>{default} Отправлено в беседу сервера VK!");
			}
			else
			{
				char szOutOfLimits[128];
				Format(szOutOfLimits, sizeof(szOutOfLimits),"{darkred}>>{default} Можно писать в VK %i раз в раунд!",iMsgPerRound);
				CPrintToChat(iClient, szOutOfLimits);
			}
			return Plugin_Handled;
		}
		else
		{
			CPrintToChat(iClient, "{darkred}>>{default} Тебе отключили чатик! :<");
			return Plugin_Handled;
		}
	}
	else
	{
		if (iVK[iClient] < iMsgPerRound)
		{
			char szURL[1024];
			char szSteam[32];
			GetClientAuthId(iClient, AuthId_Steam2, szSteam, sizeof(szSteam), true);
			FormatEx(szURL, sizeof(szURL), "https://api.vk.com/method/messages.send?chat_id=1&message=Игрок \"%N\" (%s) пишет :NEWLINE NEWLINE%s&v=5.80&access_token=%s",iClient,szSteam,szText,szToken);
			//Костыль :
			ReplaceString(szURL, sizeof(szURL), " ", "%20", false);
			ReplaceString(szURL, sizeof(szURL), "NEWLINE", "%0A", false);
			//Дебаг :
			//PrintToConsole(iClient,szURL);
			Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, szURL);
			SteamWorks_SetHTTPCallbacks(req, OnRequestComplete);
			SteamWorks_SetHTTPRequestHeaderValue(req, "User-Agent", "Test");
			SteamWorks_SendHTTPRequest(req);
			iVK[iClient]++;
			CPrintToChat(iClient, "{yellow}>>{default} Отправлено в беседу сервера VK!");
		}
		else
		{
			char szOutOfLimits[128];
			Format(szOutOfLimits, sizeof(szOutOfLimits),"{darkred}>>{default} Можно писать в VK %i раз в раунд!",iMsgPerRound);
			CPrintToChat(iClient, szOutOfLimits);
		}
		return Plugin_Handled;
	}
}

public int OnRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	int length;
	SteamWorks_GetHTTPResponseBodySize(hRequest, length);
	char[] sBody = new char[length];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, length);
	//Дебаг :
	PrintToConsoleAll(sBody);
}
