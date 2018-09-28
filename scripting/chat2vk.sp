#include <sourcemod>
#include <cstrike>
#include <colorvariables>
#include <SteamWorks>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <sourcecomms>

ConVar g_sourcecomms;
ConVar g_token;
ConVar g_servername;
ConVar g_msgPerRound;
ConVar g_logging;
int iVK[MAXPLAYERS + 1];
int iMsgPerRound;
char szToken[128];
char szSName[256];

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
	g_sourcecomms = AutoExecConfig_CreateConVar("g_sourcecomms", "0", "SourceComms Support : 1=ON, 0=OFF");
	g_token = AutoExecConfig_CreateConVar("g_token", "thisisyourtoken", "Токен от группы VK. Подробнее : https://pastebin.com/YQ2dwGWY");
	g_msgPerRound = AutoExecConfig_CreateConVar("g_msgPerRound", "3", "Сколько сообщений в раунд можно отправить.");
	g_servername = AutoExecConfig_CreateConVar("g_servername", "1", "Указывать название сервера в сообщении.");
	g_logging = AutoExecConfig_CreateConVar("g_logging", "1", "Писать логи в csgo/addons/sourcemod/logs.");
	AutoExecConfig_ExecuteFile();
	RegConsoleCmd("sm_vk", VKsay, "Send a message to VK conversation");
	HookEvent("round_start", RoundStart, EventHookMode_Post);
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
    {
        iVK[i] = 0;
    }
}

public OnConfigsExecuted()
{
	g_token.GetString(szToken, 128);
	iMsgPerRound = g_msgPerRound.IntValue;
	if (g_servername.BoolValue)
	{
		static Handle:hHostName;
		if(hHostName == INVALID_HANDLE)
		{
			if( (hHostName = FindConVar("hostname")) == INVALID_HANDLE)
			{
				PrintToServer("[Chat2VK] Плагин сломался.");
				return;
			}
		}
		GetConVarString(hHostName, szSName, sizeof(szSName));
		ReplaceString(szSName, sizeof(szSName), " ", "%20", false);
	}
}

public Action VKsay(int iClient, int iArgs)
{
	if(iArgs < 1)
	{
		CPrintToChat(iClient,"{green}>>{default} Использование команды : {green}/vk текст!");
		return Plugin_Handled;
	}
	
	char szText[256];
	GetCmdArgString(szText, sizeof(szText));
	
	if (iVK[iClient] < iMsgPerRound)
	{
		//Проверка SourceComms
		if ((g_sourcecomms.BoolValue) && (SourceComms_GetClientGagType(iClient) != bNot))
		{
			CPrintToChat(iClient, "{darkred}>>{default} Тебе отключили чатик! :<");
			return Plugin_Handled;
		}
		char szURL[1024];
		char szSteam[32];
		GetClientAuthId(iClient, AuthId_Steam2, szSteam, sizeof(szSteam), true);
	

		if (g_servername.BoolValue)
		{
			FormatEx(szURL, sizeof(szURL), "https://api.vk.com/method/messages.send?chat_id=1&message=Игрок \"%N\" (%s) пишет :NEWLINE NEWLINE%s NEWLINE NEWLINEСервер : %s&v=5.80&access_token=%s",iClient,szSteam,szText,szSName,szToken);
		}
		else
		{
			FormatEx(szURL, sizeof(szURL), "https://api.vk.com/method/messages.send?chat_id=1&message=Игрок \"%N\" (%s) пишет :NEWLINE NEWLINE%s&v=5.80&access_token=%s",iClient,szSteam,szText,szToken);
		}
		
		//Костыль :
		ReplaceString(szURL, sizeof(szURL), " ", "%20", false);
		ReplaceString(szURL, sizeof(szURL), "NEWLINE", "%0A", false);
		
		//Решётки сломают вам запрос в вк, придётся их удалить :
		ReplaceString(szURL, sizeof(szURL), "#", "%20", false);
		
		//Дебаг :
		//PrintToConsole(iClient,szURL);
		
		Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, szURL);
		SteamWorks_SetHTTPCallbacks(req, OnRequestComplete);
		SteamWorks_SetHTTPRequestHeaderValue(req, "User-Agent", "Test");
		SteamWorks_SendHTTPRequest(req);
		iVK[iClient]++;
		CPrintToChat(iClient, "{yellow}>>{default} Отправлено в беседу сервера VK!");
		if (g_logging.BoolValue)
		{
			LogAction(iClient, -1, "\"%L\" отправил : %s", iClient, szURL);
		}
	}
	else
	{
		char szOutOfLimits[128];
		Format(szOutOfLimits, sizeof(szOutOfLimits),"{darkred}>>{default} Можно писать в VK %i раз в раунд!",iMsgPerRound);
		CPrintToChat(iClient, szOutOfLimits);
	}
	return Plugin_Handled;
}

public int OnRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	int length;
	SteamWorks_GetHTTPResponseBodySize(hRequest, length);
	char[] sBody = new char[length];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, length);
	//Дебаг :
	//PrintToConsoleAll(sBody);
	if (g_logging.BoolValue)
	{
		LogMessage("Отклик VK : %s",sBody);
	}
}