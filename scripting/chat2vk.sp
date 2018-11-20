#include <sourcemod>
#include <cstrike>
#include <colorvariables>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <sourcecomms>


#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <ripext>

#define STEAMWORKS_ON()	(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest")	== FeatureStatus_Available)
#define RIP_ON()		(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "HTTPClient.HTTPClient")			== FeatureStatus_Available)

#pragma semicolon 1
#pragma newdecls required

ConVar g_sourcecomms;
ConVar g_token;
ConVar g_servername;
ConVar g_msgPerRound;
ConVar g_logging;
ConVar g_check;
ConVar g_link;

int iVK[MAXPLAYERS + 1];
int iMsgPerRound;
char szToken[128];
char szSName[256];
char szPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "Chat 2 VK",
	author = "XTANCE",
	description = "Send messages to VK conversation",
	version = "1.1",
	url = "https://t.me/xtance"
};

#if defined _ripext_included_
HTTPClient g_hHTTPClient ;
#endif
	
public void OnPluginStart()
{
	#if defined _ripext_included_
	g_hHTTPClient = new HTTPClient("https://api.vk.com");
	#endif

	AutoExecConfig_SetFile("chat2vk", "sourcemod");
	AutoExecConfig_SetCreateFile(true);
	g_sourcecomms = CreateConVar("g_sourcecomms", "0", "SourceComms Support : 1=ON, 0=OFF");
	g_token = AutoExecConfig_CreateConVar("g_token", "thisisyourtoken", "Токен от группы VK. Подробнее : https://pastebin.com/YQ2dwGWY");
	g_msgPerRound = AutoExecConfig_CreateConVar("g_msgPerRound", "3", "Сколько сообщений в раунд можно отправить.");
	g_servername = AutoExecConfig_CreateConVar("g_servername", "1", "Указывать название сервера в сообщении.");
	g_logging = AutoExecConfig_CreateConVar("g_logging", "1", "Писать логи в csgo/addons/sourcemod/logs");
	g_check = AutoExecConfig_CreateConVar("g_check", "0", "[BETA] Запрещает слова из файла addons/sourcemod/data/chat2vk/check.txt \nПрисутствуют баги.");
	g_link = AutoExecConfig_CreateConVar("g_link", "1", "Вставлять ссылку на игрока вместо его SteamID в сообщении.");
	AutoExecConfig_ExecuteFile();
	RegConsoleCmd("sm_vk", VKsay, "Send a message to VK conversation");
	RegConsoleCmd("sm_send", VKsend, "Command to send message from VK to server, don't touch it!");
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	
	CreateDirectory("addons/sourcemod/data/chat2vk",511);
	BuildPath(Path_SM, szPath, sizeof(szPath), "data/chat2vk/check.txt");
	if (g_check.BoolValue)
	{
		if (!FileExists(szPath))
		{
			PrintToServer("[Chat2VK] Нет файла для проверки, делаю его сам!");
			Handle hFile = OpenFile(szPath,"w");
			CloseHandle(hFile);
		}
	}
}

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErr_max)
{
#if defined _SteamWorks_Included
	MarkNativeAsOptional("SteamWorks_CreateHTTPRequest");
	MarkNativeAsOptional("SteamWorks_SetHTTPCallbacks");
	MarkNativeAsOptional("SteamWorks_SetHTTPRequestHeaderValue");
	MarkNativeAsOptional("SteamWorks_SendHTTPRequest");
	MarkNativeAsOptional("SteamWorks_GetHTTPResponseBodySize");
	MarkNativeAsOptional("SteamWorks_GetHTTPResponseBodyData");
#endif
#if defined _ripext_included_
	MarkNativeAsOptional("HTTPClient.HTTPClient");
	MarkNativeAsOptional("HTTPClient.SetHeader");
	MarkNativeAsOptional("HTTPClient.Post");
	MarkNativeAsOptional("HTTPResponse.Status.get");
#endif
	return APLRes_Success;
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
    {
        iVK[i] = 0;
    }
}

public void OnConfigsExecuted()
{
	g_token.GetString(szToken, 128);
	iMsgPerRound = g_msgPerRound.IntValue;
	if (g_servername.BoolValue)
	{
		Handle hHostName;
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

public Action VKsend(int iClient, int iArgs)
{
	if ((iArgs < 1) || (iClient > 0))
	{
		PrintToServer("[Chat2VK] %N зачем-то написал /send", iClient);
		return Plugin_Handled;
	}
	else
	{
		char szTextFromVK[400], szTipaBuffer[2][400];
		GetCmdArgString(szTextFromVK, sizeof(szTextFromVK));
		ReplaceString(szTextFromVK, sizeof(szTextFromVK), "\"", "", false);
		ExplodeString(szTextFromVK, "&", szTipaBuffer, sizeof(szTipaBuffer), sizeof(szTipaBuffer[]));
		
		if (strlen(szTipaBuffer[1]) < 1){
			char szURL[1024], szName[2048], szRawMap[64], szMap[3][64];
			int iC = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					Format(szName, sizeof(szName), "%s%N ^:-", szName,i);
					iC++;
				}
			}
			GetCurrentMap(szRawMap, sizeof(szRawMap));
			ExplodeString(szRawMap, "/", szMap, sizeof(szMap), sizeof(szMap[]));
			if (g_servername.BoolValue)
			{
				FormatEx(szURL, sizeof(szURL), "https://api.vk.com/method/messages.send?chat_id=1&message=Сервер : %s^:-Онлайн : %i игроков. Карта : %s^:-^:-%s&v=5.80&access_token=%s",szSName,iC,szMap[2],szName,szToken);
			}
			else
			{
				FormatEx(szURL, sizeof(szURL), "https://api.vk.com/method/messages.send?chat_id=1&message=Онлайн : %i игроков. Карта : %s^:-^:-%s&v=5.80&access_token=%s",iC,szMap[2],szName,szToken);
			}

			ReplaceString(szURL, sizeof(szURL), " ", "%20");
			ReplaceString(szURL, sizeof(szURL), "^:-", "%0A");
			ReplaceString(szURL, sizeof(szURL), "#", "%23");
			ReplaceString(szURL, sizeof(szURL), "+", "%2B");

			SendMessage(szURL);
			
			return Plugin_Handled;
		}
		
		CPrintToChatAll("{darkblue}>>{default} %s {darkblue}пишет из VK :", szTipaBuffer[0]);
		CPrintToChatAll( "{darkblue}>>{default} %s " , szTipaBuffer[1] );
		
		if (g_logging.BoolValue)
		{
			LogAction(iClient, -1, "%s пишет из VK : %s", szTipaBuffer[0],szTipaBuffer[1]);
		}
		return Plugin_Handled;
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
	if (g_check.BoolValue)
	{
		Handle hFile = OpenFile(szPath, "r");
		if (hFile == INVALID_HANDLE)
		{
			PrintToServer("[Chat2VK] Сломался файл check.txt!");
			return Plugin_Stop;
		}
		char szLine[256];
		while (!IsEndOfFile(hFile) && ReadFileLine(hFile, szLine, sizeof(szLine)))
		{
			//Дебаг :
			//PrintToConsole(iClient,"Текст : %s ; юзер : %s",szLine,szText);
			
			//Проверка забаганная. Допустим в check.txt есть string. Игрок НЕ сможет послать s,st,str,stri,strin,string, НО сможет послать stringg
			//Пытаюсь исправить ситуацию... Вместо этого :
			//if (StrContains(szLine, szText, false) != -1)
			//Лепим обратную проверку :
			if ((StrContains(szLine, szText, false) != -1) || (StrContains(szText, szLine, false) != -1))
			{
				PrintToConsoleAll("Нельзя : %s",szLine);
				CPrintToChat(iClient, "{darkred}>>{default} Запрещённое сообщение! :<");
				if (g_logging.BoolValue)
				{
					LogAction(iClient, -1, "\"%L\" пытался отправить : %s, запрет на : %s", iClient, szText, szLine);
				}
				return Plugin_Handled;
			}
			//И всё равно не работает. Да и не очень хотелось...
		}
		CloseHandle(hFile);
	}
	
	if (iVK[iClient] < iMsgPerRound)
	{
		//Проверка SourceComms
		if ((g_sourcecomms.BoolValue) && (SourceComms_GetClientGagType(iClient) != bNot))
		{
			CPrintToChat(iClient, "{darkred}>>{default} Тебе отключили чатик! :<");
			return Plugin_Handled;
		}
		char szURL[1024];
		char szSteam[64];
		if (g_link.BoolValue)
		{
			GetClientAuthId(iClient, AuthId_SteamID64, szSteam, sizeof(szSteam), true);
			Format(szSteam, sizeof(szSteam), "steamcommunity.com/profiles/%s", szSteam);
		}
		else
		{
			GetClientAuthId(iClient, AuthId_Steam2, szSteam, sizeof(szSteam), true);
		}
		
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
		ReplaceString(szURL, sizeof(szURL), "#", "%23", false);
		
		//Дебаг :
		//PrintToConsole(iClient,szURL);
	
		SendMessage(szURL);

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

void SendMessage(const char[] szURL)
{
	if (STEAMWORKS_ON())
	{
		SW_SendMessage(szURL);
	} else if (RIP_ON())
	{
		RIP_SendMessage(szURL);
	} else
	{
		LogError("Ошибка отправки сообщения!");
	}
}

#if defined _ripext_included_
void RIP_SendMessage(const char[] szURL)
{
	g_hHTTPClient.SetHeader("User-Agent", "Test");

	g_hHTTPClient.Get(szURL[19], OnRequestCompleteRIP);
}

public void OnRequestCompleteRIP(HTTPResponse hResponse, any iData)
{
	if (hResponse.Status != HTTPStatus_OK)
	{
		LogMessage("Отклик VK : %d", hResponse.Status);
	}
}
#endif

#if defined _SteamWorks_Included
void SW_SendMessage(const char[] szURL)
{
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, szURL);
	SteamWorks_SetHTTPCallbacks(hRequest, OnRequestCompleteSW);
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "User-Agent", "Test");
	SteamWorks_SendHTTPRequest(hRequest);
}

public void OnRequestCompleteSW(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	int length;
	SteamWorks_GetHTTPResponseBodySize(hRequest, length);
	char[] sBody = new char[length];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, length);
	delete hRequest;

	if (g_logging.BoolValue)
	{
		LogMessage("Отклик VK : %s",sBody);
	}
}
#endif
