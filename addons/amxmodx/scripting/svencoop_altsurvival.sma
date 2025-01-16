#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <orpheu>
#include <hamsandwich>
#include <fun>

#pragma semicolon 1

#define PLUGIN_NAME						"Sven Co-op Alternative Survival Mode Management"
#define PLUGIN_VERSION					"1.0.0"
#define PLUGIN_AUTHOR					"szGabu"

#define NATIVE_SURV_STARTING_MSG		"Survival mode starting in "

#define RESPAWN_ENTNAME					"trigger_respawn"
#define RESPAWN_TARGETNAME				"amxx_sadvsurv_marisakirisame"

#define RELAY_ENTNAME					"trigger_relay"
#define RELAY_TARGETNAME				"amxx_sadvsurv_hakureireimu"

#define GAMEOVER_VOTE_ENTNAME			"trigger_vote"
#define GAMEOVER_VOTE_TARGETNAME		"amxx_sadvsurv_sanaekochiya"

#define RESTART_ENTNAME					"trigger_vote"
#define RESTART_TARGETNAME				"amxx_sadvsurv_cirno"

#define GAMEEND_ENTNAME					"game_end"
#define GAMEEND_TARGETNAME				"amxx_sadvsurv_sakuyaizayoi"

#define RESPAWN_SPAWNFLAG_DEADONLY		2
#define RESPAWN_SPAWNFLAG_DONTMOVE		4

//tasks
#define ENABLESURV_TASKID				878749
#define INITIALREINF_TASKID 			48774
#define SPAWN_PROTECT_TASKID 			874298
#define UNSTUCK_TASKID 					154777
#define REINFORCEMENT_COOLDOWN_TASKID 	785642

/* Private Data - Update might be required when new version comes. */
#define m_pPlayer 				420
#define g_iUnixDiff 			16

new const Float:g_fSize[][3] = {
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
};

new const g_szMonsterList[][] = {
	"monster_alien_babyvoltigore",
	"monster_alien_controller",
	"monster_alien_grunt",
	"monster_alien_slave",
	"monster_alien_tor",
	"monster_alien_voltigore",
	"monster_apache",
	"monster_assassin_repel",
	"monster_babycrab",
	"monster_babygarg",
	"monster_barnacle",
	"monster_barney",
	"monster_barney_dead",
	"monster_bigmomma",
	"monster_blkop_osprey",
	"monster_blkop_apache",
	"monster_bloater",
	"monster_bodyguard",
	"monster_bullchicken",
	"monster_chumtoad",
	"monster_cleansuit_scientist",
	"monster_cockroach",
	"monster_flyer_flock",
	"monster_furniture",
	"monster_gargantua",
	"monster_generic",
	"monster_gman",
	"monster_gonome",
	"monster_grunt_ally_repel",
	"monster_grunt_repel",
	"monster_handgrenade",
	"monster_headcrab",
	"monster_hevsuit_dead",
	"monster_hgrunt_dead",
	"monster_houndeye",
	"monster_human_assassin",
	"monster_human_grunt",
	"monster_human_grunt_ally",
	"monster_human_grunt_ally_dead",
	"monster_human_medic_ally",
	"monster_human_torch_ally",
	"monster_hwgrunt",
	"monster_hwgrunt_repel",
	"monster_ichthyosaur",
	"monster_kingpin",
	"monster_leech",
	"monster_male_assassin",
	"monster_medic_ally_repel",
	"monster_miniturret",
	"monster_nihilanth",
	"monster_osprey",
	"monster_otis",
	"monster_otis_dead",
	"monster_pitdrone",
	"monster_rat",
	"monster_robogrunt",
	"monster_robogrunt_repel",
	"monster_satchel",
	"monster_scientist",
	"monster_scientist_dead",
	"monster_sentry",
	"monster_shockroach",
	"monster_shocktrooper",
	"monster_sitting_scientist",
	"monster_snark",
	"monster_sqknest",
	"monster_stukabat",
	"monster_tentacle",
	"monster_torch_ally_repel",
	"monster_tripmine",
	"monster_turret",
	"monster_zombie",
	"monster_zombie_barney",
	"monster_zombie_soldier",
};

new g_hRespawnEnt		= 0;
new g_hRelayEnt     	= 0;
new g_hGameOverEnt     	= 0;
new g_hRestartEnt     	= 0;
new g_hGameEndEnt     	= 0;

#define SURVMODE_DISABLED	0
#define SURVMODE_NORESPAWN	1
#define SURVMODE_WAVES		2

#define TIMERMODE_NORMAL	0
#define TIMERMODE_DAMAGE	1

#define	WAVEMODE_FIXED		0
#define WAVEMODE_PERPLAYER	1

//plugin cvars
new bool:g_bPluginEnabled;
new g_iSurvivalMode;
new g_iSurvivalMinPlayers;
new Float:g_fSurvivalStartDelay;
new bool:g_bSurvivalActSpawn;
new g_iTimerMode;
new Float:g_fTimerAdvance;
new g_iWaveMode;
new Float:g_fWaveTime;
new Float:g_fSpawnProtectionTime;
new g_iSpawnProtectionShellThickness;

//native cvars
new g_cvarObserverMode;
new g_cvarObserverCyclic;

//these are used when nextmapper is enabled
new g_cvarPluginSurvStartDelay;
new g_cvarAntiRushWaitStart;

// rest of stuff
new bool:g_bSurvivalEnabled = false;
new bool:g_bAllDead = false;
new bool:g_bDamagedRecently = false;
new bool:g_bWaveIncoming = false;
new bool:g_bInfoActivated = false;
new g_iPluginFlags;
new bool:g_bIsValidReviveBeacon[MAX_PLAYERS+1] = false;
new g_iRespawnTimeLeft = 0;

new OrpheuFunction:g_hSurvivalActivateNow, OrpheuFunction:g_hSurvivalToggle;
new OrpheuHook:g_hSurvivalActivateNowHookPre, OrpheuHook:g_hSurvivalToggleHookPre;
#pragma unused g_hSurvivalActivateNowHookPre
#pragma unused g_hSurvivalToggleHookPre

new g_cvarPluginEnabled;
new g_cvarSurvivalMode;
new g_cvarSurvivalMinPlayers;
new g_cvarSurvivalStartDelay;
new g_cvarSurvivalActSpawn;
new g_cvarTimerMode;
new g_cvarTimerAdvance;
new g_cvarWaveMode;
new g_cvarWaveTime;
new g_cvarSpawnProtectionTime;
new g_cvarSpawnProtectionShellThickness;

/**
 * Called during server/map precache phase to initialize essential plugin components.
 * Sets up native ConVar pointers and hooks the survival mode activation function.
 * 
 * @return void
 */
public plugin_precache()
{
	g_iPluginFlags = plugin_flags();

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_precache() - Called");

	g_cvarObserverMode = get_cvar_pointer("mp_observer_mode");
	g_cvarObserverCyclic = get_cvar_pointer("mp_observer_cyclic");

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_precache() - Pointers Ready");

	g_hSurvivalActivateNow = OrpheuGetFunction("SC_SurvivalMode_ActivateNow");
	g_hSurvivalActivateNowHookPre = OrpheuRegisterHook(g_hSurvivalActivateNow, "SurvivalActivateNowPre", OrpheuHookPre);

	g_hSurvivalToggle = OrpheuGetFunction("SC_SurvivalMode_Toggle");
	g_hSurvivalToggleHookPre = OrpheuRegisterHook(g_hSurvivalToggle, "SurvivalTogglePre", OrpheuHookPre);
}

/**
 * Hook callback that intercepts and blocks the native survival mode activation.
 * Used to implement custom survival mode behavior.
 *
 * @param ptrThis Reference pointer from the engine
 *
 * @return OrpheuSupercede Prevents the original function from executing
 */
public OrpheuHookReturn:SurvivalActivateNowPre(ptrThis)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
        server_print("[DEBUG] svencoop_advsurvival.amxx::SurvivalActivateNowPre() - Called");

	return OrpheuSupercede;
}

/**
 * Hook callback that intercepts and blocks the native survival mode toggle.
 * Used to implement custom survival mode behavior.
 *
 * @param ptrThis Reference pointer from the engine
 *
 * @return OrpheuSupercede Prevents the original function from executing
 */
public OrpheuHookReturn:SurvivalTogglePre(ptrThis)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
        server_print("[DEBUG] svencoop_advsurvival.amxx::SurvivalTogglePre() - Called");

	return OrpheuSupercede;
}

/**
 * Initializes the plugin, registers commands and creates necessary ConVars.
 * Sets up all the configuration variables that control the plugin's behavior.
 *
 * @return void
 */
public plugin_init()
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_init() - Called");

	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	g_cvarPluginEnabled = create_cvar("amx_survival_enabled", "1", FCVAR_NONE, "Enables the plugin");
	g_cvarSurvivalMode = create_cvar("amx_survival_mode", "2", FCVAR_NONE, "Determines the mode of survival mode. 0 = Completely disable survival. 1 = Survival enabled, no respawns. 2 = Survival enabled, timer based.");
	g_cvarSurvivalMinPlayers = create_cvar("amx_survival_min_players", "2", FCVAR_NONE, "Mininum amount of players to enable survival mode. Lowest possible value is 1, to always enable survival mode.");
	g_cvarSurvivalStartDelay = create_cvar("amx_survival_start_delay", "30", FCVAR_NONE, "How much time to wait before activating survival mode.");
	g_cvarSurvivalActSpawn = create_cvar("amx_survival_activation_spawn", "1", FCVAR_NONE, "Determines if the plugin should spawn players whenever a spawn point is activated. (Most of the time these represent checkpoints)");
	g_cvarTimerMode = create_cvar("amx_survival_timer_mode", "1", FCVAR_NONE, "Determines the behavior of the timer when the timer based survival is enabled. 0 = Fixed timer advance. 1 = Timer advances only when dealing damage");
	g_cvarTimerAdvance = create_cvar("amx_survival_timer_advance", "10.0", FCVAR_NONE, "Determines how much time the timer should advance when dealing damage. Only works with 'amx_survival_timer_mode 2', no effect otherwise");
	g_cvarWaveMode = create_cvar("amx_survival_wave_mode", "1", FCVAR_NONE, "If we are using the wave mode timer, how should the plugin calculate the time to respawn. 0 = Fixed defined time. 1 = Multiply 'amx_survival_wave_time' value per player.");
	g_cvarWaveTime = create_cvar("amx_survival_wave_time", "25", FCVAR_NONE, "Time to wait before next spawn wave");
	g_cvarSpawnProtectionTime = create_cvar("amx_survival_sp", "2", FCVAR_NONE, "Determines spawn protection. How much time players should be protected. 0 to disable spawn protection");
	g_cvarSpawnProtectionShellThickness = create_cvar("amx_survival_sp_shell_thick", "25", FCVAR_NONE, "If players are under the spawn protection effect, how thick should be the visible shield. 0 to disable shield.");
	
	register_message(get_user_msgid("TextMsg"), "Message_TextMsg");
}

public Message_TextMsg(iMsg, iType, iEntity)
{
	if(g_bPluginEnabled)
	{
		static szMsg[64]; 
		get_msg_arg_string(2, szMsg, charsmax(szMsg));
		if(containi(szMsg, NATIVE_SURV_STARTING_MSG) == 0)
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
				server_print("[DEBUG] svencoop_altsurvival.amxx::Message_TextMsg() - Server is sending native message");

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

/**
 * Called after all configuration files have been executed.
 * Initializes plugin variables, sets up hooks, and creates necessary entities.
 * Also handles compatibility with the Nextmapper plugin.
 *
 * @return void
 */
public plugin_cfg()
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_cfg() - Called");

	//sadly, we can't bind nor hook because AMXX crashes on Sven Co-op if we do
	g_bPluginEnabled = get_pcvar_bool(g_cvarPluginEnabled);
	g_iSurvivalMode = get_pcvar_num(g_cvarSurvivalMode);
	g_iSurvivalMinPlayers = get_pcvar_num(g_cvarSurvivalMinPlayers);
	g_fSurvivalStartDelay = get_pcvar_float(g_cvarSurvivalStartDelay);
	g_bSurvivalActSpawn = get_pcvar_bool(g_cvarSurvivalActSpawn);
	g_iTimerMode = get_pcvar_num(g_cvarTimerMode);
	g_fTimerAdvance = get_pcvar_float(g_cvarTimerAdvance);
	g_iWaveMode = get_pcvar_num(g_cvarWaveMode);
	g_fWaveTime = get_pcvar_float(g_cvarWaveTime);
	g_fSpawnProtectionTime = get_pcvar_float(g_cvarSpawnProtectionTime);
	g_iSpawnProtectionShellThickness = get_pcvar_num(g_cvarSpawnProtectionShellThickness);

	// find_plugin_byfile returns a positive if it's registered in the plugin file even 
	// if it failed to load for whatever reason; Just check if its cvar exists
	new bool:bSvenCoopNextmapperRunning = get_cvar_pointer("amx_sven_antirush_wait_start") > 0;

	if(bSvenCoopNextmapperRunning)
	{
		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_cfg() - Sven Co-op Nextmapper Running");

		g_cvarPluginSurvStartDelay = get_cvar_pointer("amx_survival_start_delay");
		g_cvarAntiRushWaitStart = get_cvar_pointer("amx_sven_antirush_wait_start");
		new Float:fThisDelay = get_pcvar_float(g_cvarPluginSurvStartDelay);
		new Float:fNmDelay = get_pcvar_float(g_cvarAntiRushWaitStart);

		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_cfg() - fThisDelay is %f, fNmDelay is %f", fThisDelay, fNmDelay);

		if(fThisDelay <= fNmDelay)
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
				server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_cfg() - Native delay less than nextmapper delay, adjusting");

			g_fSurvivalStartDelay = (fNmDelay + 2.0);
		}
	}

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_cfg() - Hooking Events");

	RegisterHam(Ham_Killed, "player", "Event_PlayerKilled_Post", true);

	register_concmd("amx_respawn", "Command_RespawnDeadPlayers", ADMIN_BAN, "Respawns All Players"); 

	register_concmd("amx_survival_activate_now", "Command_SurvivalActivateNow", ADMIN_BAN, "Tries to activate survival mode"); 
	
	RegisterHam(Ham_Use, "info_player_start", "Event_SpawnActivation_Post", true);  
	RegisterHam(Ham_Use, "info_player_deathmatch", "Event_SpawnActivation_Post", true);  
	RegisterHam(Ham_Use, "info_player_coop", "Event_SpawnActivation_Post", true);  
	RegisterHam(Ham_Use, "info_player_dm2", "Event_SpawnActivation_Post", true);  
	RegisterHam(Ham_Use, "trigger_respawn", "Event_SpawnActivation_Post", true);  
	
	RegisterHam(Ham_SC_EndRevive, "player", "Event_PlayerRevived_Post", true);
	RegisterHam(Ham_SC_Player_SpecialSpawn, "player", "Event_PlayerRevived_Post", true);

	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_medkit", "Event_PrepareRevive");
	RegisterHam(Ham_Weapon_RetireWeapon, "weapon_medkit", "Event_RetireMedkit_Post", true);

	RegisterHam(Ham_Spawn, "player", "Event_PlayerSpawn_Post", true);

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::plugin_cfg() - Done Hooking Events");
	
	//add custom 
	g_bAllDead = false;
	g_bWaveIncoming = false;
	g_bInfoActivated = false;
	
	RegisterMonsterHooks();

	set_task(1.0, "Task_ClockFunction", _, _, _, "b");

	SetupNeededEnts();
}

/**
 * Creates and configures necessary game entities for plugin functionality.
 * Sets up respawn triggers, relay entities, and vote handling entities.
 *
 * @return void
 */
public SetupNeededEnts()
{
	g_hRespawnEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, RESPAWN_ENTNAME));
	dllfunc(DLLFunc_Spawn, g_hRespawnEnt);
	set_pev(g_hRespawnEnt, pev_targetname, RESPAWN_TARGETNAME);
	set_pev(g_hRespawnEnt, pev_spawnflags, RESPAWN_SPAWNFLAG_DEADONLY | RESPAWN_SPAWNFLAG_DONTMOVE);

	g_hRelayEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, RELAY_ENTNAME));
	dllfunc(DLLFunc_Spawn, g_hRelayEnt);
	set_pev(g_hRelayEnt, pev_targetname, RELAY_TARGETNAME);

	g_hGameOverEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, GAMEOVER_VOTE_ENTNAME));
	set_pev(g_hGameOverEnt, pev_message, "Game Over^nRestart map?");
	set_pev(g_hGameOverEnt, pev_frags, 20.0); //20 seconds to vote
	set_pev(g_hGameOverEnt, pev_health, 60.0); //60% needed to continue
	set_pev(g_hGameOverEnt, pev_target, RESTART_TARGETNAME);
	set_pev(g_hGameOverEnt, pev_netname, GAMEEND_TARGETNAME);
	set_pev(g_hGameOverEnt, pev_noise, GAMEEND_TARGETNAME);
	set_pev(g_hGameOverEnt, pev_targetname, GAMEOVER_VOTE_TARGETNAME);
	dllfunc(DLLFunc_Spawn, g_hGameOverEnt);

	g_hRestartEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, RESTART_ENTNAME));
	set_pev(g_hRestartEnt, pev_targetname, RESTART_TARGETNAME);
	dllfunc(DLLFunc_Spawn, g_hRestartEnt);
	RegisterHam(Ham_Use, RESTART_ENTNAME, "Event_RestartVoteOption_Use", true);

	g_hGameEndEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, GAMEEND_ENTNAME));
	set_pev(g_hGameEndEnt, pev_targetname, GAMEEND_TARGETNAME);

	server_print("[NOTICE] %s is free to download and distribute! If you paid for this plugin YOU GOT SCAMMED. Visit https://github.com/szGabu for all my plugins.", PLUGIN_NAME);
}

/**
 * Handler for restart vote entity usage.
 * Executes map restart when triggered.
 *
 * @param iEnt Entity index of the vote trigger
 *
 * @return HAM_IGNORED Continue normal execution
 */
public Event_RestartVoteOption_Use(iEnt)
{
	if(iEnt == g_hRestartEnt)
		server_cmd("restart");

	return HAM_IGNORED;
}

/**
 * Handles player disconnection events.
 *
 * Updates player counts and survival mode state.
 *
 * @param iClient Index of disconnecting client
 *
 * @return void
 */
public client_disconnected(iClient)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::client_disconnected() - Called on %N", iClient);

	if(g_bPluginEnabled)
		RequestFrame("Event_PlayerKilled_Post", iClient);
}

/**
 * Handles preparation for player revival with medkit.
 * Marks the reviving player as being a valid revival beacon.
 *
 * @param iWeaponId Index of the medkit weapon entity
 *
 * @return void
 */
public Event_PrepareRevive(iWeaponId)
{
	if(g_bPluginEnabled)
	{
		new iClient = get_pdata_ehandle(iWeaponId, m_pPlayer, g_iUnixDiff);
		g_bIsValidReviveBeacon[iClient] = true;
	}
}

/**
 * Post-hook for medkit retirement (switching weapons).
 * Clears revival beacon status.
 *
 * @param iWeaponId Index of the medkit weapon entity
 *
 * @return void
 */
public Event_RetireMedkit_Post(iWeaponId)
{
	if(g_bPluginEnabled)
	{
		new iClient = get_pdata_ehandle(iWeaponId, m_pPlayer, g_iUnixDiff);
		g_bIsValidReviveBeacon[iClient] = false;
	}
}

/**
 * Handles new player connections.
 * Checks and updates reinforcement conditions.
 *
 * @param iClient Index of connecting client
 *
 * @return void
 */
public client_putinserver(iClient)
{
	if(!g_bPluginEnabled)
		return;
		
	if(g_iSurvivalMode != SURVMODE_DISABLED && g_bSurvivalEnabled)
		CheckReinforcementConditions();
}

/**
 * Evaluates if reinforcement wave should be triggered.
 * Initiates wave timer if conditions are met.
 *
 * @return void
 */
CheckReinforcementConditions()
{
	if(GetPlayerCount(1) > 0 && g_bPluginEnabled)
	{
		if(g_iSurvivalMode == SURVMODE_WAVES && !g_bWaveIncoming && GetPlayerCount(2) > 0)
		{
			if(!task_exists(INITIALREINF_TASKID))
			{
				if(g_iWaveMode == WAVEMODE_FIXED)
					g_iRespawnTimeLeft = floatround(g_fWaveTime);
				else
					g_iRespawnTimeLeft = floatround(g_fWaveTime*(GetPlayerCount(0)));
				g_bWaveIncoming = true;
				set_task(10.0, "CallForReinforcements", INITIALREINF_TASKID);
			}
		}
	}
}

/**
 * Post-hook for player death events.
 * Handles game over conditions and reinforcement scheduling.
 *
 * @param iClient Index of killed player
 *
 * @return HAM_IGNORED Continue normal execution
 *
 * @note `client_disconnected()` also calls this
 */
public Event_PlayerKilled_Post(iClient)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
	{
		if(is_user_connected(iClient))
			server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerKilled_Post() - Called on %N", iClient);
		else
			server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerKilled_Post() - Called on Player %d (Disconnected)", iClient);
	}

	if(!g_bPluginEnabled)
		return HAM_IGNORED;

	if(g_iSurvivalMode == SURVMODE_DISABLED)
		return HAM_IGNORED;

	g_bIsValidReviveBeacon[iClient] = false;
	
	if(g_bSurvivalEnabled)
	{
		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerKilled_Post() - Survival is enabled");

		new iAlivePlayers = GetPlayerCount(1);

		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerKilled_Post() - iAlivePlayers is %d", iAlivePlayers);

		if(iAlivePlayers == 0)
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
				server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerKilled_Post() - No more living players, ending game.");

			client_print(0, print_chat, "No more players alive. Game over.");
			set_task(5.0, "TriggerVoteEntity");
		}
		else 
			CheckReinforcementConditions();
	}
	
	//we shouldnt really need to stop this event from happening
	return HAM_IGNORED;
}

/**
 * Triggers the game over vote entity.
 * Called when all players are dead.
 *
 * @return void
 */
public TriggerVoteEntity()
{
	ExecuteHamB(Ham_Use, g_hGameOverEnt, g_hGameOverEnt, g_hGameOverEnt, 1, 1.0);
}

/**
 * Post-hook for monster damage events.
 * 
 * Updates timer advancement based on combat activity. Once this happens we need to
 * tell the plugin the players are actually advancing the map, so the respawn clock
 * might advance. (This is to prevent players waiting for reinforcements in a safe place
 * causing an stale standard gameplay with long respawn times)
 *
 * @param iMonster Index of damaged monster entity
 * @param fDamage Amount of damage dealt
 *
 * @return void
 */
public Event_GetDamagePoints_Post(iMonster, iAttacker, iInflictor, Float:fDamage)
{
	if(iAttacker >= 1 && iAttacker <= MaxClients && fDamage > 1.0)
	{
		g_bDamagedRecently = true;
		
		if(!task_exists(REINFORCEMENT_COOLDOWN_TASKID))
			set_task(g_fTimerAdvance, "Task_ReinforcementCooldown", REINFORCEMENT_COOLDOWN_TASKID);
		else
		{
			remove_task(REINFORCEMENT_COOLDOWN_TASKID);
			set_task(g_fTimerAdvance, "Task_ReinforcementCooldown", REINFORCEMENT_COOLDOWN_TASKID);
		}
	}
}

 /**
 * Post-hook for spawn point activation. It sets up a boolean to 
 * prevent players from spawning multiple times in the next frame due to multiple
 * spawn entities being activated due to having the same targetname
 *
 * @return void
 */
public Event_SpawnActivation_Post()
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::Event_SpawnActivation_Post() - Called");

	if(!g_bInfoActivated && g_bPluginEnabled && g_iSurvivalMode != SURVMODE_DISABLED && g_bSurvivalEnabled && g_bSurvivalActSpawn)
	{
		g_bInfoActivated = true;
		RespawnAllPlayers();
		set_task(1.0, "Task_InfoActivatedCooldown");
	}
}

/**
 * Timer task to reset spawn point activation status.
 * Prevents multiple spawns from single activation.
 *
 * @return void
 */
public Task_InfoActivatedCooldown()
{
	g_bInfoActivated = false;
}

/**
 * Recurring timer task that manages reinforcement wave countdown.
 * Updates HUD messages and triggers reinforcements.
 *
 * @return void
 */
public Task_ClockFunction()
{
	if(!g_bPluginEnabled || !g_bSurvivalEnabled || g_iSurvivalMode != SURVMODE_WAVES || !g_bWaveIncoming || task_exists(INITIALREINF_TASKID))
        return;

	if(GetPlayerCount(2) == 0 || GetPlayerCount(1) == 0)
	{
		g_bWaveIncoming = false;
		return;
	}
	
	new sHud[125];
	if(g_iTimerMode == TIMERMODE_DAMAGE && !g_bDamagedRecently)
		set_hudmessage(255,0,0,0.5,0.8,0,1.0,2.0,0.0,0.0,10);
	else 
	{
		set_hudmessage(50,135,180,0.5,0.8,0,1.0,2.0,0.0,0.0,10);
		g_iRespawnTimeLeft--;
	}

	formatex(sHud, charsmax(sHud), "Reinforcements will arrive in ^n%i seconds!", g_iRespawnTimeLeft);
	show_hudmessage(0, sHud);
	
	if(g_iRespawnTimeLeft == 0)
		ReinforcementsArrived();
}

/**
 * Timer task to reset recent damage status.
 * Controls timer advancement in damage-based mode.
 *
 * @return void
 */
public Task_ReinforcementCooldown()
{
	g_bDamagedRecently = false;
}

/**
 * Initiates reinforcement wave countdown.
 * Displays countdown message to players.
 *
 * @return void
 */
public CallForReinforcements()
{
	if(GetPlayerCount(2) >= 1)
		client_print(0, print_chat, "Reinforcements will arrive in %i seconds!", g_iRespawnTimeLeft);
	else
		g_bWaveIncoming = false;
}

/**
 * Handles arrival of reinforcement wave.
 * Respawns dead players and resets wave status.
 *
 * @return void
 */
public ReinforcementsArrived()
{
	if(!g_bAllDead && g_bWaveIncoming)
	{
		if(GetPlayerCount(2) > 0)
		{
			client_print(0, print_chat, "Reinforcements have arrived!");
			RespawnAllPlayers();
		}
		g_bWaveIncoming = false;
	}
}

/**
 * Post-hook for player spawn events.
 * Handles survival mode activation and spawn protection.
 *
 * @param iClient Index of spawned player
 *
 * @return HAM_IGNORED Continue normal execution
 */
public Event_PlayerSpawn_Post(iClient)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
	{
		server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerSpawn_Post() - Called on %N", iClient);
		server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerSpawn_Post() - g_bPluginEnabled is %b", g_bPluginEnabled);
		server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerSpawn_Post() - g_iSurvivalMode is %d", g_iSurvivalMode);
		server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerSpawn_Post() - is_user_alive(iClient) is %d", is_user_alive(iClient));
	}

	if(!g_bPluginEnabled || g_iSurvivalMode == SURVMODE_DISABLED) //who cares if it's called in observer?
		return HAM_IGNORED; 

	SurvivalActivateNow();

	if(g_fSpawnProtectionTime > 0.0) 
		RequestFrame("SpawnProtectEnable", iClient);
		
	return HAM_IGNORED;
}

SurvivalActivateNow()
{
	if(!g_bSurvivalEnabled && GetPlayerCount(0) >= g_iSurvivalMinPlayers)
	{
		if(!task_exists(ENABLESURV_TASKID))
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
				server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerSpawn_Post() - I want to enable survival mode");
			new iEnableSurvivalTime = floatround(g_fSurvivalStartDelay);
			client_print(0, print_chat, "Enabling survival mode in %d seconds", iEnableSurvivalTime);
			server_print("Enabling survival mode in %d seconds", iEnableSurvivalTime);
			client_print(0, print_center, "Enabling survival mode in %d seconds", iEnableSurvivalTime);
			set_task(g_fSurvivalStartDelay, "EnableSurvival", ENABLESURV_TASKID);
		}
	}
	else if(!g_bSurvivalEnabled)
	{
		client_print(0, print_chat, "Not enough players to activate survival mode. Minimum %d", g_iSurvivalMinPlayers);

		if(task_exists(ENABLESURV_TASKID))
			remove_task(ENABLESURV_TASKID);
	}
}

/**
 * Enables survival mode.
 * Sets up necessary game settings and notifies players.
 *
 * @return void
 */
public EnableSurvival()
{
	RespawnAllPlayers();
	client_print(0, print_chat, "Survival mode enabled. No more respawning allowed!");
	client_print(0, print_center, "Survival mode enabled.^nNo more respawning allowed!");
	set_pcvar_bool(g_cvarObserverMode, true);
	set_pcvar_bool(g_cvarObserverCyclic, true);
	g_bSurvivalEnabled = true;
}

/**
 * Enables temporary invulnerability for newly spawned players.
 * Applies visual effects and sets up protection removal timer.
 *
 * @param iClient Index of player to protect
 *
 * @return void
 */
public SpawnProtectEnable(iClient) // This is the function for the task_on godmode
{
   set_user_godmode(iClient, 1);
   set_user_rendering(iClient, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, g_iSpawnProtectionShellThickness);
   set_task(g_fSpawnProtectionTime, "Task_SpawnProtectDisable", SPAWN_PROTECT_TASKID+iClient);
}

/**
 * Timer task to remove spawn protection.
 * Removes godmode and visual effects.
 *
 * @param iTaskId Task ID containing client index
 *
 * @return void
 */
public Task_SpawnProtectDisable(iTaskId) 
{
	new iClient = iTaskId-SPAWN_PROTECT_TASKID;
	if(!is_user_connected(iClient))
		return;
	else
	{
		set_user_godmode(iClient, 0);
		set_user_rendering(iClient, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	}
}

/**
 * Post-hook for player revival events. Handles revival location adjustment and spawn protection.
 *
 * The function will attempt to teleport revived players to a safe location in case they fell
 * into a dangerous place like lava or a laser
 *
 * @param iClient Index of revived player
 *
 * @return HAM_IGNORED Continue normal execution
 */
public Event_PlayerRevived_Post(iClient)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::Event_PlayerRevived_Post() - Called on %N", iClient);

	if(GetPlayerCount(2) == 0)
		g_bWaveIncoming = false;

	if(g_fSpawnProtectionTime > 0.0)
	{
		if(!task_exists(SPAWN_PROTECT_TASKID+iClient))
		{
			new Float:fPlayerOrigin[3];
			new iOther = -1;
			pev(iClient, pev_origin, fPlayerOrigin);
			while((iOther = find_ent_in_sphere(iOther, fPlayerOrigin, 150.0)))
			{
				if(iOther == 0 
				|| iOther > MaxClients 
				|| !g_bIsValidReviveBeacon[iOther]
				|| pev(iOther, pev_deadflag) & DEAD_DYING
				|| pev(iOther, pev_deadflag) & DEAD_DEAD
				|| iOther == iClient)
					continue;

				new Float:fOtherOrigin[3];
				pev(iOther, pev_origin, fOtherOrigin);
				set_pev(iClient, pev_origin, fOtherOrigin);
				set_task(0.5, "Task_UnstuckPlayer", UNSTUCK_TASKID+iClient);
				break;
			}
			SpawnProtectEnable(iClient);
		}
	}

	return HAM_IGNORED;
}

/**
 * Timer task to unstuck players after teleportation.
 * Attempts to find valid position if player is stuck.
 *
 * @param iTaskId Task ID containing client index
 *
 * @return void
 */
public Task_UnstuckPlayer(iTaskId)
{
	new iClient = iTaskId-UNSTUCK_TASKID;
	if (is_user_connected(iClient) && is_user_alive(iClient)) 
	{
		static Float:fClientOrigin[3], iHullType;
		static Float:fClientMins[3];
		static Float:fDesiredOrigin[3];
		pev(iClient, pev_origin, fClientOrigin);
		iHullType = pev(iClient, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;
		if (!IsHullVacant(fClientOrigin, iHullType, iClient) && !get_user_noclip(iClient) && !(pev(iClient,pev_solid) & SOLID_NOT)) 
		{
			pev(iClient, pev_mins, fClientMins);
			fDesiredOrigin[2] = fClientOrigin[2];
			for(new iSize=0; iSize < sizeof g_fSize; ++iSize) 
			{
				fDesiredOrigin[0] = fClientOrigin[0]-fClientMins[0]*g_fSize[iSize][0];
				fDesiredOrigin[1] = fClientOrigin[1]-fClientMins[1]*g_fSize[iSize][1];
				fDesiredOrigin[2] = fClientOrigin[2]-fClientMins[2]*g_fSize[iSize][2];
				if (IsHullVacant(fDesiredOrigin, iHullType, iClient)) 
				{
					engfunc(EngFunc_SetOrigin, iClient, fDesiredOrigin);
					set_pev(iClient,pev_velocity,{0.0,0.0,0.0});
					iSize = sizeof g_fSize;
				}
			}
		}
	}
}

/**
 * Admin command handler for manual respawn of all dead players.
 * Validates admin privileges and respawns players.
 *
 * @param iClient Index of admin using command
 * @param iLevel Required admin level
 * @param iCommandId Command identifier
 *
 * @return PLUGIN_HANDLED Command handled status
 */
public Command_RespawnDeadPlayers(iClient, iLevel, iCommandId)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
	{
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_RespawnDeadPlayers() - Called");
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_RespawnDeadPlayers() - iClient is %d", iClient);
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_RespawnDeadPlayers() - iLevel is %d", iLevel);
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_RespawnDeadPlayers() - iCommandId is %d", iCommandId);
	}

	//this condition fixes a bug where the command Command_RespawnDeadPlayers() gets called randomly
	//unsure what is causing it 
	if(iClient == 0 && iLevel == -520167424 && iCommandId == 0)
		return PLUGIN_HANDLED;

	if (!cmd_access(iClient, iLevel, iCommandId, 1))
		return PLUGIN_HANDLED;
		
	if(GetPlayerCount(2) == 0)
	{
		client_print(iClient, print_console, "There's no one to respawn.^n");
		return PLUGIN_HANDLED;
	}

	RespawnAllPlayers();
	g_bWaveIncoming = false;
	client_print(0, print_center, "An admin has spawned everyone!");

	return PLUGIN_HANDLED;
}

public Command_SurvivalActivateNow(iClient, iLevel, iCommandId)
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
	{
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_SurvivalActivateNow() - Called");
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_SurvivalActivateNow() - iClient is %d", iClient);
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_SurvivalActivateNow() - iLevel is %d", iLevel);
		server_print("[DEBUG] svencoop_altsurvival.amxx::Command_SurvivalActivateNow() - iCommandId is %d", iCommandId);
	}

	if(iClient == 0 || iLevel == -520167424 || iCommandId == 0)
		return PLUGIN_HANDLED;

	if (!cmd_access(iClient, iLevel, iCommandId, 1))
		return PLUGIN_HANDLED;

	SurvivalActivateNow();

	return PLUGIN_HANDLED;
}

/**
 * Function to respawn all dead players immediately.
 * Triggers respawn entity to handle revival.
 *
 * @return void
 */
RespawnAllPlayers()
{
	ExecuteHamB(Ham_Use, g_hRespawnEnt, g_hRelayEnt, g_hRelayEnt, 0, 0.0);
}

/**
 * Checks if a position has space for an entity hull.
 *
 * @param fOrigin Float array containing position coordinates
 * @param iHull Hull type to check
 * @param iClient Player index to ignore in collision
 *
 * @return bool True if position is vacant, false if occupied
 */
bool:IsHullVacant(const Float:fOrigin[3], iHull, iClient) 
{
	static iTrace;
	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, iHull, iClient, iTrace);
	if (!get_tr2(iTrace, TR_StartSolid) || !get_tr2(iTrace, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
		return true;
	
	return false;
}

/**
 * Counts players based on specified criteria.
 *
 * @param iType Player type to count:
 *              0 = All players
 *              1 = Living players only
 *              2 = Dead players only
 *
 * @return int Number of matching players
 */
GetPlayerCount(iType)
{
	new iCount = 0;
	for(new iClient=1;iClient <= MaxClients;iClient++)
	{
		if(is_user_connected(iClient))
		{
			switch(iType)
			{
				case 1:
				{
					if(is_user_alive(iClient))
						iCount++;
				}
				case 2:
				{
					if(!is_user_alive(iClient))
						iCount++;
				}
				default:
				{
					iCount++;
				}
			}
		}
	}
	return iCount;
}

/**
 * Registers damage event hooks for all monster entities.
 * Used to track combat activity for timer advancement.
 *
 * @return void
 */
RegisterMonsterHooks()
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] svencoop_altsurvival.amxx::RegisterMonsterHooks() - Called");

	for(new iCursor; iCursor < sizeof g_szMonsterList; iCursor++)
		RegisterHam(Ham_SC_GetDamagePoints, g_szMonsterList[iCursor], "Event_GetDamagePoints_Post", true);
}