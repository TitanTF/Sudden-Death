#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

bool
	g_bWaiting = false;
	
Handle
	g_hHUD = INVALID_HANDLE;
	
public Plugin myinfo = 
{
	name = "Sudden Death",
	author = "myst",
	description = "A team wins on capture, made for KOTH maps.",
	version = "1.0",
	url = "https://titan.tf"
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("ctf_flag_captured", Event_FlagCaptured);
	HookEvent("teamplay_point_captured", Event_PointCaptured);
	
	g_hHUD = CreateHudSynchronizer();
}

public void OnConfigsExecuted() {
	SetupConVars();
}

public void TF2_OnWaitingForPlayersStart() {	
	g_bWaiting = true;
}

public void TF2_OnWaitingForPlayersEnd() {
	g_bWaiting = false;
}

public Action Event_RoundStart(Handle hEvent, const char[] sEventName, bool bDontBroadcast) 
{
	if (!g_bWaiting)
		CreateTimer(1.0, Timer_Explanation, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_FlagCaptured(Handle hEvent, const char[] sEventName, bool bDontBroadcast) {
	ServerCommand("sv_cheats 1; mp_forcewin %i; sv_cheats 0;", GetEventInt(hEvent, "capping_team"));
}

public Action Event_PointCaptured(Handle hEvent, const char[] sEventName, bool bDontBroadcast) {
	ServerCommand("sv_cheats 1; mp_forcewin %i; sv_cheats 0;", GetEventInt(hEvent, "team"));
}

public Action Event_PlayerSpawn(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	float flHealth; float flSpeed; float flTargetSpeed;
	
	switch (TF2_GetPlayerClass(iClient))
	{
		case TFClass_Scout:  	flHealth = 150.0 - 125.0, flSpeed = 400.0, flTargetSpeed = 450.0;
		case TFClass_Soldier:	flHealth = 1.0, 		  flSpeed = 240.0, flTargetSpeed = 290.0;
		case TFClass_Pyro:		flHealth = 250.0 - 175.0, flSpeed = 300.0, flTargetSpeed = 350.0;
		case TFClass_DemoMan:	flHealth = 200.0 - 175.0, flSpeed = 280.0, flTargetSpeed = 330.0;
		case TFClass_Heavy:		flHealth = 500.0 - 300.0, flSpeed = 230.0, flTargetSpeed = 280.0;
		case TFClass_Engineer:	flHealth = 200.0 - 125.0, flSpeed = 300.0, flTargetSpeed = 350.0;
		case TFClass_Medic:		flHealth = 200.0 - 150.0, flSpeed = 320.0, flTargetSpeed = 370.0;
		case TFClass_Sniper:	flHealth = 200.0 - 125.0, flSpeed = 300.0, flTargetSpeed = 350.0;
		case TFClass_Spy:		flHealth = 200.0 - 125.0, flSpeed = 320.0, flTargetSpeed = 370.0;
	}
	
	TF2Attrib_SetByName(iClient, "move speed bonus", flTargetSpeed/flSpeed);
	TF2Attrib_RemoveByName(iClient, "max health additive bonus");
	TF2Attrib_SetByName(iClient, "max health additive bonus", flHealth);
	
	for (int iSlot = 0; iSlot < 5; iSlot++)
	{ 
		int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
		
		if (IsValidEntity(iWeapon))
		{
			TF2Attrib_SetByName(iWeapon, "engy building health bonus", 1.25);
			TF2Attrib_SetByName(iWeapon, "clip size bonus", 2.0);
			TF2Attrib_SetByName(iWeapon, "faster reload rate", 0.5);
			TF2Attrib_SetByName(iWeapon, "fire rate bonus", 0.75);
			TF2Attrib_SetByName(iWeapon, "ammo regen", 1.0);
			TF2Attrib_SetByName(iWeapon, "mod see enemy health", 1.0);
		}
	}
	
	TF2_RegeneratePlayer(iClient);
	
	TF2_AddCondition(iClient, TFCond_Buffed, 3.0);
	TF2_AddCondition(iClient, TFCond_DefenseBuffed, 5.0);
	TF2_AddCondition(iClient, TFCond_SpeedBuffAlly, 5.0);
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (IsValidClient(iClient))
	{
		int deathflags = GetEventInt(hEvent, "death_flags");
		if (!(deathflags & 32))
		{
			CreateTimer(2.0, Timer_Respawn, iClient, TIMER_FLAG_NO_MAPCHANGE);
			PrintHintText(iClient, "Respawning in 2s");
		}
	}
}

public Action Timer_Respawn(Handle hTimer, any iClient)
{
	TF2_RespawnPlayer(iClient);
}

public void SetupConVars()
{
	SetConVarInt(FindConVar("mp_bonusroundtime"), 5);
	SetConVarInt(FindConVar("mp_disable_respawn_times"), 0);
	SetConVarInt(FindConVar("mp_respawnwavetime"), 99999);
	SetConVarInt(FindConVar("tf_weapon_criticals"), 0);
	SetConVarInt(FindConVar("tf_weapon_criticals_melee"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
	SetConVarInt(FindConVar("mp_autoteambalance"), 1);
}

public Action Timer_Explanation(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SetHudTextParams(-1.0, 0.2, 3.0, 255, 255, 255, 255, 1, 0.2, 0.2, 0.2);
			ShowSyncHudText(i, g_hHUD, "This is Sudden Death. Capture the objective to win.");
		}
	}
	
	CreateTimer(3.5, Timer_Explanation2, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Explanation2(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SetHudTextParams(-1.0, 0.2, 4.0, 255, 255, 255, 255, 1, 0.2, 0.2, 0.2);
			ShowSyncHudText(i, g_hHUD, "Total Mayhem - You reload and shoot faster with more clip size.\n \nYou also move faster and have more health.");
		}
	}
	
	CreateTimer(4.5, Timer_Explanation4, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Explanation4(Handle hTimer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SetHudTextParams(-1.0, 0.2, 2.0, 255, 255, 255, 255, 1, 0.2, 0.2, 0.2);
			ShowSyncHudText(i, g_hHUD, "Good luck!");
		}
	}
}

stock int GetPlayersCount() 
{ 
	int iCount, i; iCount = 0; 

	for (i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) >= 2) 
			iCount++; 
	}

	return iCount; 
}

stock bool IsValidClient(int iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}