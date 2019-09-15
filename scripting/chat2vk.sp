#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <basecomm>

#undef REQUIRE_EXTENSIONS
#tryinclude <SteamWorks>
#tryinclude <ripext>

#define STEAMWORKS_ON()	(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest")	== FeatureStatus_Available)
#define RIP_ON()		(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "HTTPClient.HTTPClient")			== FeatureStatus_Available)

#pragma semicolon 1
#pragma newdecls required

#if defined _ripext_included_
HTTPClient g_hHTTPClient;
#endif

int iChats, iCSGO, iIncludeServerName, iBaseComms, iMessagesPerRound, iLogging, iVK[MAXPLAYERS + 1], iSteam[MAXPLAYERS + 1];
char sToken[128],sServerName[256], sSection[100],sValueID[100], sText[MAXPLAYERS+1][300], sName[MAXPLAYERS+1][64];
Menu menu_chats;

public Plugin myinfo =
{
	name = "Chat 2 VK",
	author = "XTANCE",
	description = "Send messages to VK conversation",
	version = "2.0",
	url = "https://t.me/xtance"
};

public void OnPluginStart()
{
	#if defined _ripext_included_
	if (RIP_ON()) g_hHTTPClient = new HTTPClient("https://api.vk.com");
	#endif

	
	RegConsoleCmd("sm_vk", VKsay, "Посылает сообщение в VK");
	RegServerCmd("sm_send", VKsend, "Посылает сообщение из VK на сервер - не трогать");
	RegServerCmd("sm_web_getplayers", Action_Web_GetPlayers, "Получает массив с игроками - не трогать");
	
	HookEvent("round_start", RoundStart, EventHookMode_Post);
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/chat2vk.ini");
	KeyValues kv = new KeyValues("Chat2VK");
	
	if (!FileExists(sPath, false)){
		if (kv.JumpToKey("VK_Settings", true)){
			kv.SetNum("BaseComms", 1);
			kv.SetString("VKToken", "thisisyourtoken");
			kv.SetNum("MessagesPerRound", 3);
			kv.SetNum("IncludeServerName", 1);
			kv.SetNum("Logging", 1);
			kv.SetNum("CSGO_Colors", 1);
			kv.Rewind();
		}
		if (kv.JumpToKey("VK_Commands", true)){
			kv.SetString("Отправить в беседу", "2000000001");
			kv.SetString("Отправить гл. админу", "142805811");
			kv.Rewind();
		}
		kv.ExportToFile(sPath);
	}
	
	if (kv.ImportFromFile(sPath)){
		if (kv.JumpToKey("VK_Settings", false)){
			iBaseComms = kv.GetNum("BaseComms");
			kv.GetString("VKToken", sToken, sizeof(sToken));
			iMessagesPerRound = kv.GetNum("MessagesPerRound");
			iIncludeServerName = kv.GetNum("IncludeServerName");
			iLogging = kv.GetNum("Logging");
			iCSGO = kv.GetNum("CSGO_Colors");
			kv.Rewind();
		}
		if (kv.JumpToKey("VK_Commands", false)){
			kv.GotoFirstSubKey(false);
			menu_chats = new Menu(hmenu);
			menu_chats.SetTitle("Выберите получателя:");
			do {
				kv.GetSectionName(sSection, sizeof(sSection));
				kv.GetString(NULL_STRING, sValueID, sizeof(sValueID));
				menu_chats.AddItem(sValueID, sSection);
				if (iLogging) PrintToServer("[Chat2VK] ChatID: %s, Text: %s", sValueID, sSection);
				iChats++;
			} while (kv.GotoNextKey(false));
		}
	} else SetFailState("[Chat2VK] KeyValues Error!");
	delete kv;
	
	
	for (int i = 1; i<=MaxClients; i++) OnClientPostAdminCheck(i);
}

public void OnConfigsExecuted(){
	if (iIncludeServerName){
		Handle hHostName;
		if(hHostName == INVALID_HANDLE)
		{
			if( (hHostName = FindConVar("hostname")) == INVALID_HANDLE)
			{
				PrintToServer("[Chat2VK] Плагин сломался.");
				return;
			}
		}
		GetConVarString(hHostName, sServerName, sizeof(sServerName));
		ReplaceString(sServerName, sizeof(sServerName), " ", "%20", false);
	}
}

public void OnClientPostAdminCheck(int iClient) {
	if (IsClientInGame(iClient) && !IsFakeClient(iClient)){
		iSteam[iClient] = GetSteamAccountID(iClient, true);
		GetClientName(iClient, sName[iClient], sizeof(sName[]));
		ReplaceString(sName[iClient], sizeof(sName[]), "\\", "", false);
		ReplaceString(sName[iClient], sizeof(sName[]), "\"", "", false);
	}
}

public Action Action_Web_GetPlayers(int iArgs){
	PrintToServer("[");
	for (int i = 1; i<=MaxClients; i++){
		if (IsClientInGame(i) && !IsFakeClient(i)){
			PrintToServer("{\"name\": \"%s\", \"steamid\": %i, \"k\": %i, \"d\": %i},",sName[i],iSteam[i],GetClientFrags(i),GetClientDeaths(i));
			//Format(sJson, sizeof(sJson), "{\"name\": \"%s\", \"steamid\": %i, \"k\": %i, \"d\": %i},%s",sName[i],iSteam[i],GetClientFrags(i),GetClientDeaths(i),sJson);
		}
	}
	PrintToServer("]ArrayEnd");
	
	/*for (int i = 1; i<=MaxClients; i++){
		if (IsClientInGame(i) && !IsFakeClient(i)){
			Format(sJson, sizeof(sJson), "{\"name\": \"%s\", \"steamid\": %i, \"k\": %i, \"d\": %i},%s",sName[i],iSteam[i],GetClientFrags(i),GetClientDeaths(i),sJson);
		}
	}
	Format(sJson, sizeof(sJson), "[%s]", sJson);
	ReplaceString(sJson, sizeof(sJson), ",]", "]", false); // :D
	ReplyToCommand(0, sJson);*/
	return Plugin_Handled;
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
	MarkNativeAsOptional("HTTPClient.Get");
	MarkNativeAsOptional("HTTPResponse.Status.get");
#endif
	return APLRes_Success;
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) iVK[i] = 0;
}

public Action VKsend(int iArgs)
{
	if (iArgs < 1)
	{
		PrintToServer("[Chat2VK] Что-то пошло не так!");
		return Plugin_Handled;
	}
	else
	{
		char sVK[512], sBuffer[2][512];
		GetCmdArgString(sVK, sizeof(sVK));
		ReplaceString(sVK, sizeof(sVK), "\"", "", false);
		ExplodeString(sVK, "&", sBuffer, sizeof(sBuffer), sizeof(sBuffer[]));
		
		if (strlen(sBuffer[1]) < 1) return Plugin_Handled;
		
		if (iCSGO){
			PrintToChatAll(" \x0B>>\x01 %s \x0Bпишет из VK:", sBuffer[0]);
			PrintToChatAll( " \x0B>>\x01 %s " , sBuffer[1] );
		}
		else {
			PrintToChatAll(">> %s пишет из VK:", sBuffer[0]);
			PrintToChatAll(">> %s ", sBuffer[1]);
		}
		
		
		if (iLogging > 0) LogMessage("%s пишет из VK: %s", sBuffer[0],sBuffer[1]);
		return Plugin_Handled;
	}
}

public Action VKsay(int iClient, int iArgs)
{
	if (iClient == 0) PrintToServer("[Chat2VK] Эта команда для клиента!");
	else if (iArgs < 1) PrintToChat(iClient, "%s", iCSGO ? " \x06>>\x01 Использование команды : \x06/vk текст!" : ">> Использование команды : /vk текст");
	else if (iVK[iClient] < iMessagesPerRound)
	{
		//Проверка BaseComms
		if (iBaseComms && (BaseComm_IsClientGagged(iClient)))
		{
			PrintToChat(iClient, "%s", iCSGO ? " \x02>>\x01 Тебе отключили чатик! :<" : ">> Тебе отключили чатик! :<");
			return Plugin_Handled;
		}
		
		char sSteam[64];
		GetCmdArgString(sText[iClient], sizeof(sText[]));
		GetClientAuthId(iClient, AuthId_SteamID64, sSteam, sizeof(sSteam), true);
		Format(sSteam, sizeof(sSteam), "steamcommunity.com/profiles/%s", sSteam);
		
		if (iIncludeServerName) Format(sText[iClient], sizeof(sText[]), "Игрок \"%N\" [ %s ] пишет :NWLN NWLN%s NWLN NWLNСервер : %s",iClient,sSteam,sText[iClient],sServerName);
		else Format(sText[iClient], sizeof(sText[]), "Игрок \"%N\" [ %s ] пишет :NWLN NWLN%s",iClient,sSteam,sText[iClient]);
		
		if (iChats < 1) PrintToChat(iClient, "%s", iCSGO ? " \x0B>> \x01 Chat2VK не работает.. временно." : ">> Chat2VK не работает.. временно.");
		else if (iChats == 1)
		{
			SendMessage(StringToInt(sValueID), sText[iClient]);
			iVK[iClient]++;
			if (iLogging) LogAction(iClient, -1, "\"%L\" отправил : %s", iClient, sText[iClient]);
		}
		else menu_chats.Display(iClient, 0);
	}
	else PrintToChat(iClient, " >> Можно писать в VK %i раз в раунд!",iMessagesPerRound);
	return Plugin_Handled;
}

public int hmenu(Menu m, MenuAction action, int iClient, int iParam2){
	switch (action){
		case MenuAction_Select:{
			char sID[50];
			m.GetItem(iParam2, sID, sizeof(sID));
			SendMessage(StringToInt(sID), sText[iClient]);
			iVK[iClient]++;
			if (iLogging) LogAction(iClient, -1, "\"%L\" отправил : %s", iClient, sText[iClient]);
		}
	}
	return 0;
}

void SendMessage(int iID, const char[] sMessage)
{
	char sURL[2000];
	if(iID >= 2000000000){
		iID -= 2000000000;
		FormatEx(sURL, sizeof(sURL), "https://api.vk.com/method/messages.send?v=5.101&random_id=%i&access_token=%s&chat_id=%i&message=%s",
			GetRandomInt(0, 100500),
			sToken,
			iID,
			sMessage
		);
	}
	else{
		FormatEx(sURL, sizeof(sURL), "https://api.vk.com/method/messages.send?v=5.101&random_id=%i&access_token=%s&user_id=%i&message=%s",
			GetRandomInt(0, 100500),
			sToken,
			iID,
			sMessage
		);
	}
	
	//Костыли :
	ReplaceString(sURL, sizeof(sURL), " ", "%20", false);
	ReplaceString(sURL, sizeof(sURL), "NWLN", "%0A", false);
	ReplaceString(sURL, sizeof(sURL), "#", "%23", false);
	if (STEAMWORKS_ON()) SW_SendMessage(sURL);
	else if (RIP_ON()) RIP_SendMessage(sURL);
	else LogError("Ошибка отправки сообщения!");
}

#if defined _ripext_included_
void RIP_SendMessage(const char[] sURL)
{
	g_hHTTPClient.SetHeader("User-Agent", "Test");
	g_hHTTPClient.Get(sURL[19], OnRequestCompleteRIP);
}

public void OnRequestCompleteRIP(HTTPResponse hResponse, any iData)
{
	if (hResponse.Status != HTTPStatus_OK && iLogging) LogMessage("Отклик VK : %d", hResponse.Status);
}
#endif

#if defined _SteamWorks_Included
void SW_SendMessage(const char[] sURL)
{
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sURL);
	SteamWorks_SetHTTPCallbacks(hRequest, OnRequestCompleteSW);
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "User-Agent", "Test");
	SteamWorks_SendHTTPRequest(hRequest);
}

public int OnRequestCompleteSW(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	int length;
	SteamWorks_GetHTTPResponseBodySize(hRequest, length);
	char[] sBody = new char[length];
	SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, length);
	delete hRequest;

	if (iLogging) LogMessage("Отклик VK : %s",sBody);
}
#endif