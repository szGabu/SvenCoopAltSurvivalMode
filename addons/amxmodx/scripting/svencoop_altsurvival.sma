#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <hamsandwich>
#include <fun>

#pragma semicolon   1
#pragma dynamic     32768

//RequestFrame does not work properly (https://github.com/alliedmodders/amxmodx/issues/1039) 
//This is the next best thing, do not blame me
#define TECHNICAL_IMMEDIATE    			0.1

//tasks
#define TASKID_ENABLESURVIVAL			878749
#define TASKID_INITIALREINFORCEMENTS 	485879
#define TASKID_REINFORCEMENTCOOLDOWN 	785642
#define TASKID_SPAWNPROTECT 			874298
#define TASKID_UNSTUCK 					154777
#define TASKID_CLIENTDISCONNECTED_AFTER 187518
#define TASKID_CLOCKFUNCTION			781845
#define TASKID_TRIGGERVOTEENTITY		578875
#define TASKID_INFOACTIVATEDCOOLDOWN	874187
#define TASKID_PLAYERSPAWN_POST_AFTER	378487

#define PLUGIN_NAME						"Sven Co-op Alternative Survival Mode Management"
#define PLUGIN_VERSION					"RC-25w23a"
#define PLUGIN_AUTHOR					"szGabu"

#define NATIVE_SURV_STARTING_MSG		"Survival mode starting in "

#define RESPAWN_CLASSNAME				"trigger_respawn"
#define RESPAWN_TARGETNAME				"amxx_sadvsurv_marisakirisame"

#define RELAY_CLASSNAME					"trigger_relay"
#define RELAY_TARGETNAME				"amxx_sadvsurv_hakureireimu"

#define GAMEOVER_VOTE_CLASSNAME			"trigger_vote"
#define GAMEOVER_VOTE_TARGETNAME		"amxx_sadvsurv_sanaekochiya"

#define RESTART_CLASSNAME				"trigger_vote"
#define RESTART_TARGETNAME				"amxx_sadvsurv_cirno"

#define GAMEEND_CLASSNAME				"game_end"
#define GAMEEND_TARGETNAME				"amxx_sadvsurv_sakuyaizayoi"

#define EMERGENCY_SPAWN_TARGETNAME		"amxx_sadvsurv_rinkaenbyou"

#define SF_RESPAWN_DEADONLY				2
#define SF_RESPAWN_DONTMOVE				4

/* Player Start Spawn Flags */
#define SF_SPAWN_START_OFF				2

/* Private Data - Update might be required when new version comes. */
#define m_pPlayer 						420
#define g_iUnixDiff 					16

#if AMXX_VERSION_NUM < 183
#define MAX_PLAYERS                 	32
#define MAX_NAME_LENGTH             	32
#define MaxClients                  	get_maxplayers()
#define __BINARY__                  	"svencoop_altsurvival.amxx"
#define get_pcvar_bool(%1) 	        	(get_pcvar_num(%1) == 1)
#define set_pcvar_bool(%1) 	        	set_pcvar_num(%1)
#define find_player_ex(%1)				(find_player(%1))
#define FindPlayer_MatchUserId			"k"
#endif

#define IsValidUserIndex(%1)            (1 <= (%1) <= MaxClients)

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
	"monster_zombie_soldier"
};

new g_hRespawnEnt		= 0;
new g_hRelayEnt     	= 0;
new g_hGameOverEnt     	= 0;
new g_hRestartEnt     	= 0;
new g_hGameEndEnt     	= 0;

enum {
	SURVMODE_DISABLED = 0,
	SURVMODE_NORESPAWN,
	SURVMODE_WAVES
};

enum {
	TIMERMODE_NORMAL = 0,
	TIMERMODE_DAMAGE
};

enum {
	WAVEMODE_FIXED = 0,
	WAVEMODE_PERPLAYER,
	WAVEMODE_EXPONENTIAL,
};

//these are used when nextmapper is enabled
new g_cvarPluginSurvStartDelay;
new g_cvarAntiRushWaitStart;

// rest of stuff
new bool:g_bSurvivalEnabled = false;
new bool:g_bAllDead = false;
new bool:g_bDamagedRecently = false;
new bool:g_bWaveIncoming = false;
new bool:g_bInfoActivated = false;
new bool:g_bGameEnded = false;
new g_iPluginFlags;
new bool:g_bIsValidReviveBeacon[MAX_PLAYERS+1] = { false, ... };
new g_iRespawnTimeLeft = 0;
new g_szSpawnPointLastTargetName[MAX_NAME_LENGTH];

// plugin convars
new g_cvarPluginEnabled;
new g_cvarSurvivalMode;
new g_cvarSurvivalMinPlayers;
new g_cvarSurvivalStartDelay;
new g_cvarSurvivalActSpawn;
new g_cvarTimerMode;
new g_cvarTimerAdvance;
new g_cvarWaveMode;
new g_cvarWaveExpMinTime;
new g_cvarWaveTime;
new g_cvarSpawnProtectTime;
new g_cvarSpawnProtectShellThick;

//native convars
new g_cvarNativeSurvMinPlayers;
new g_cvarNativeSurvMode;
new g_cvarNativeSurvNextmap;
new g_cvarNativeSurvRetries;
new g_cvarNativeSurvStartDelay;
new g_cvarNativeSurvStartOn;
new g_cvarNativeSurvSupported;
new g_cvarNativeSurvVoteAllow;

new g_cvarObserverMode;
new g_cvarObserverCyclic;

// convar variables
new bool:g_bPluginEnabled;
new g_iSurvivalMode;
new g_iSurvivalMinPlayers;
new Float:g_fSurvivalStartDelay;
new bool:g_bSurvivalActSpawn;
new g_iTimerMode;
new Float:g_fTimerAdvance;
new g_iWaveMode;
new g_iWaveMinTime;
new Float:g_fWaveTime;
new Float:g_fSpawnProtectTime;
new g_iSpawnProtectShellThick;

new Array:g_rgAvailableSpawnPoints;
new bool:g_bEmergencySpawning = false;

/**
 * Initializes the plugin, registers commands and creates necessary ConVars.
 * Sets up all the configuration variables that control the plugin's behavior.
 *
 * @return void
 */
public plugin_init()
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::plugin_init() - Called", __BINARY__);

	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

	#if AMXX_VERSION_NUM < 183
	g_cvarPluginEnabled = register_cvar("amx_survival_enabled", "1");
	g_cvarSurvivalMode = register_cvar("amx_survival_mode", "2");
	g_cvarSurvivalMinPlayers = register_cvar("amx_survival_min_players", "2");
	g_cvarSurvivalStartDelay = register_cvar("amx_survival_start_delay", "30");
	g_cvarSurvivalActSpawn = register_cvar("amx_survival_activation_spawn", "1");
	g_cvarTimerMode = register_cvar("amx_survival_timer_mode", "1");
	g_cvarTimerAdvance = register_cvar("amx_survival_timer_advance", "10.0");
	g_cvarWaveMode = register_cvar("amx_survival_wave_mode", "1");
	g_cvarWaveExpMinTime = register_cvar("amx_survival_wave_exponential_min_value", "1");
	g_cvarWaveTime = register_cvar("amx_survival_wave_time", "25");
	g_cvarSpawnProtectTime = register_cvar("amx_survival_sp", "2");
	g_cvarSpawnProtectShellThick = register_cvar("amx_survival_sp_shell_thick", "25");
	#else
	g_cvarPluginEnabled = create_cvar("amx_survival_enabled", "1", FCVAR_NONE, "Enables the plugin");
	g_cvarSurvivalMode = create_cvar("amx_survival_mode", "2", FCVAR_NONE, "Determines the mode of survival mode. 0 = Completely disable survival. 1 = Survival enabled, no respawns. 2 = Survival enabled, timer based.");
	g_cvarSurvivalMinPlayers = create_cvar("amx_survival_min_players", "2", FCVAR_NONE, "Mininum amount of players to enable survival mode. Lowest possible value is 1, to always enable survival mode.");
	g_cvarSurvivalStartDelay = create_cvar("amx_survival_start_delay", "30", FCVAR_NONE, "How much time to wait before activating survival mode.");
	g_cvarSurvivalActSpawn = create_cvar("amx_survival_activation_spawn", "1", FCVAR_NONE, "Determines if the plugin should spawn players whenever a spawn point is activated. (Most of the time these represent checkpoints)");
	g_cvarTimerMode = create_cvar("amx_survival_timer_mode", "1", FCVAR_NONE, "Determines the behavior of the timer when the timer based survival is enabled. 0 = Fixed timer advance. 1 = Timer advances only when dealing damage");
	g_cvarTimerAdvance = create_cvar("amx_survival_timer_advance", "10.0", FCVAR_NONE, "Determines how much time the timer should advance when dealing damage. Only works with 'amx_survival_timer_mode 2', no effect otherwise");
	g_cvarWaveMode = create_cvar("amx_survival_wave_mode", "1", FCVAR_NONE, "If we are using the wave mode timer, how should the plugin calculate the time to respawn. 0 = Fixed defined time. 1 = Multiply 'amx_survival_wave_time' value per player. 2 = Exponential, using 'amx_survival_wave_time', for every player, add half. (starting from the second one)");
	g_cvarWaveExpMinTime = create_cvar("amx_survival_wave_exponential_min_value", "1", FCVAR_NONE, "When using the exponential method, this determines what should be the minimum value to add to the wave time.");
	g_cvarWaveTime = create_cvar("amx_survival_wave_time", "25", FCVAR_NONE, "Time to wait before next spawn wave");
	g_cvarSpawnProtectTime = create_cvar("amx_survival_sp", "2", FCVAR_NONE, "Determines spawn protection. How much time players should be protected. 0 to disable spawn protection");
	g_cvarSpawnProtectShellThick = create_cvar("amx_survival_sp_shell_thick", "25", FCVAR_NONE, "If players are under the spawn protection effect, how thick should be the visible shield. 0 to disable shield.");
	#endif

	AutoExecConfig();

	g_iPluginFlags = plugin_flags();

	g_cvarObserverMode = get_cvar_pointer("mp_observer_mode");
	g_cvarObserverCyclic = get_cvar_pointer("mp_observer_cyclic");

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::plugin_init() - Pointers Ready", __BINARY__);

	register_message(get_user_msgid("TextMsg"), "Message_TextMsg");

	DisableNativeSurvival();
}

public plugin_end()
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
        server_print("[DEBUG] %s.amxx::plugin_end() - Called", __BINARY__);

	if(task_exists(TASKID_ENABLESURVIVAL))
		remove_task(TASKID_ENABLESURVIVAL);
	if(task_exists(TASKID_INITIALREINFORCEMENTS))
		remove_task(TASKID_INITIALREINFORCEMENTS);
	if(task_exists(TASKID_REINFORCEMENTCOOLDOWN))
		remove_task(TASKID_REINFORCEMENTCOOLDOWN);
	if(task_exists(TASKID_SPAWNPROTECT))
		remove_task(TASKID_SPAWNPROTECT);
	if(task_exists(TASKID_UNSTUCK))
		remove_task(TASKID_UNSTUCK);
	if(task_exists(TASKID_CLOCKFUNCTION))
		remove_task(TASKID_CLOCKFUNCTION);
	if(task_exists(TASKID_TRIGGERVOTEENTITY))
		remove_task(TASKID_TRIGGERVOTEENTITY);
	if(task_exists(TASKID_INFOACTIVATEDCOOLDOWN))
		remove_task(TASKID_INFOACTIVATEDCOOLDOWN);
	if(task_exists(TASKID_PLAYERSPAWN_POST_AFTER))
		remove_task(TASKID_PLAYERSPAWN_POST_AFTER);

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
        server_print("[DEBUG] %s.amxx::plugin_end() - Removed Tasks", __BINARY__);
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
				server_print("[DEBUG] %s::Message_TextMsg() - Server is sending native message", __BINARY__);

			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public DisableNativeSurvival()
{
	g_cvarNativeSurvMinPlayers = get_cvar_pointer("mp_survival_minplayers");
	g_cvarNativeSurvMode = get_cvar_pointer("mp_survival_mode");
	g_cvarNativeSurvNextmap = get_cvar_pointer("mp_survival_nextmap");
	g_cvarNativeSurvRetries = get_cvar_pointer("mp_survival_retries");
	g_cvarNativeSurvStartDelay = get_cvar_pointer("mp_survival_startdelay");
	g_cvarNativeSurvStartOn = get_cvar_pointer("mp_survival_starton");
	g_cvarNativeSurvSupported = get_cvar_pointer("mp_survival_supported");
	g_cvarNativeSurvVoteAllow = get_cvar_pointer("mp_survival_voteallow");

	set_pcvar_num(g_cvarNativeSurvMinPlayers, 0);
	set_pcvar_num(g_cvarNativeSurvMode, 0);
	set_pcvar_string(g_cvarNativeSurvNextmap, "");
	set_pcvar_num(g_cvarNativeSurvRetries, 0);
	set_pcvar_float(g_cvarNativeSurvStartDelay, 0.0);
	set_pcvar_num(g_cvarNativeSurvStartOn, 0);
	set_pcvar_num(g_cvarNativeSurvSupported, 0);
	set_pcvar_num(g_cvarNativeSurvVoteAllow, 0);
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
		server_print("[DEBUG] %s::plugin_cfg() - Called", __BINARY__);

	#if AMXX_VERSION_NUM < 183
	g_bPluginEnabled = get_pcvar_num(g_cvarPluginEnabled) == 1;
	g_iSurvivalMode = get_pcvar_num(g_cvarSurvivalMode);
	g_iSurvivalMinPlayers = get_pcvar_num(g_cvarSurvivalMinPlayers);
	g_fSurvivalStartDelay = get_pcvar_float(g_cvarSurvivalStartDelay);
	g_bSurvivalActSpawn = get_pcvar_num(g_cvarSurvivalActSpawn) == 1;
	g_iTimerMode = get_pcvar_num(g_cvarTimerMode);
	g_fTimerAdvance = get_pcvar_float(g_cvarTimerAdvance);
	g_iWaveMode = get_pcvar_num(g_cvarWaveMode);
	g_iWaveMinTime = get_pcvar_num(g_cvarWaveExpMinTime);
	g_fWaveTime = get_pcvar_float(g_cvarWaveTime);
	g_fSpawnProtectTime = get_pcvar_float(g_cvarSpawnProtectTime);
	g_iSpawnProtectShellThick = get_pcvar_num(g_cvarSpawnProtectShellThick);
	#else
	//future proofing, binding and hooking currently crashes Sven Co-op but the plugin will still work if the respective cvar signature is disabled
	bind_pcvar_num(g_cvarPluginEnabled, g_bPluginEnabled);
	bind_pcvar_num(g_cvarSurvivalMode, g_iSurvivalMode);
	bind_pcvar_num(g_cvarSurvivalMinPlayers, g_iSurvivalMinPlayers);
	bind_pcvar_float(g_cvarSurvivalStartDelay, g_fSurvivalStartDelay);
	bind_pcvar_num(g_cvarSurvivalActSpawn, g_bSurvivalActSpawn);
	bind_pcvar_num(g_cvarTimerMode, g_iTimerMode);
	bind_pcvar_float(g_cvarTimerAdvance, g_fTimerAdvance);
	bind_pcvar_num(g_cvarWaveMode, g_iWaveMode);
	bind_pcvar_num(g_cvarWaveExpMinTime, g_iWaveMinTime);
	bind_pcvar_float(g_cvarWaveTime, g_fWaveTime);
	bind_pcvar_float(g_cvarSpawnProtectTime, g_fSpawnProtectTime);
	bind_pcvar_num(g_cvarSpawnProtectShellThick, g_iSpawnProtectShellThick);
	#endif

	new bool:bSvenCoopNextmapperRunning = get_cvar_pointer("amx_sven_nextmapper_enabled") > 0;

	if(bSvenCoopNextmapperRunning)
	{
		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] %s::plugin_cfg() - Sven Co-op Nextmapper Running", __BINARY__);

		g_cvarPluginSurvStartDelay = get_cvar_pointer("amx_survival_start_delay");
		g_cvarAntiRushWaitStart = get_cvar_pointer("amx_sven_antirush_wait_start");
		new Float:fThisDelay = get_pcvar_float(g_cvarPluginSurvStartDelay);
		new Float:fNmDelay = get_pcvar_float(g_cvarAntiRushWaitStart);

		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] %s::plugin_cfg() - fThisDelay is %f, fNmDelay is %f", __BINARY__, fThisDelay, fNmDelay);

		if(fThisDelay <= fNmDelay)
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
				server_print("[DEBUG] %s::plugin_cfg() - Native delay less than nextmapper delay, adjusting", __BINARY__);

			g_fSurvivalStartDelay = (fNmDelay + 2.0);
		}
	}

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::plugin_cfg() - Hooking Events", __BINARY__);

	RegisterHam(Ham_Killed, "player", "Event_PlayerKilled_Post", true);
	RegisterHam(Ham_Use, "game_end", "Event_GameEnd", false);

	register_concmd("amx_respawn", "Command_RespawnDeadPlayers", ADMIN_BAN, "Respawns All Players"); 

	register_concmd("amx_survival_activate_now", "Command_SurvivalActivateNow", ADMIN_BAN, "Tries to activate survival mode"); 
 
	RegisterHam(Ham_Use, "info_player_deathmatch", "Event_SpawnActivation_Pre", false); // deathmatch implies dm2 as well
	RegisterHam(Ham_Use, "info_player_coop", "Event_SpawnActivation_Pre", false); // coop implies start as well
	RegisterHam(Ham_Use, "info_player_deathmatch", "Event_SpawnActivation_Post", true); // ditto
	RegisterHam(Ham_Use, "info_player_coop", "Event_SpawnActivation_Post", true); // ditto

	RegisterHam(Ham_Use, "trigger_respawn", "Event_SpawnActivation_Post", true);  
	
	#if AMXX_VERSION_NUM >= 183
	//only available in latest versions of AMXX
	RegisterHam(Ham_SC_EndRevive, "player", "Event_PlayerRevived_Post", true);
	RegisterHam(Ham_SC_Player_SpecialSpawn, "player", "Event_PlayerRevived_Post", true);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_medkit", "Event_PrepareRevive");
	RegisterHam(Ham_Weapon_RetireWeapon, "weapon_medkit", "Event_RetireMedkit_Post", true);
	#endif

	RegisterHam(Ham_Spawn, "player", "Event_PlayerSpawn_Pre");
	RegisterHam(Ham_Spawn, "player", "Event_PlayerSpawn_Post", true);

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::plugin_cfg() - Done Hooking Events", __BINARY__);
	
	//add custom 
	g_bAllDead = false;
	g_bWaveIncoming = false;
	g_bInfoActivated = false;
	
	RegisterMonsterHooks();

	set_task(1.0, "Task_ClockFunction", TASKID_CLOCKFUNCTION, _, _, "b");

	SetupNeededEnts();
	MapSpecificFixes();
	ImSureThereAreSpawns();

	
}

public OnConfigsExecuted()
{
    server_print("[NOTICE] %s::OnConfigsExecuted() - %s is free to download and distribute! If you paid for this plugin YOU GOT SCAMMED. Visit https://github.com/szGabu for all my plugins.", __BINARY__, PLUGIN_NAME);
}

MapSpecificFixes()
{
	new szMap[MAX_NAME_LENGTH];
	get_mapname(szMap, charsmax(szMap));
	if(equali(szMap, "sc_robination_revised"))
	{
		// apparently, survival mode wasn't enough for the mapper, there's another game over trigger that
		// activates if all players are dead, even if survival mode is disabled
		new iEnt = 0;
		iEnt = find_ent_by_tname(0, "checknoobs"); //yes, the entity's targetname is called like this
		if(iEnt)
			remove_entity(iEnt);

		// this should be the only stepping stone, well, until the map gets updated to completely break 
		// the plugin's logic but, surely it won't happen, right? :clueless:
	}
}

ImSureThereAreSpawns()
{
	// ok, this is how it works, I'm gonna scan all possible spawn points for AVAILABLE spawn points
	// meaning spawns players can use
	g_rgAvailableSpawnPoints = ArrayCreate();

	//info_player_start
	//info_player_deathmatch
	//info_player_coop
	//info_player_dm2

	new iEnt = 0;
	while((iEnt = find_ent_by_class(iEnt, "info_player_start")))
	{
		if(pev_valid(iEnt) && !(pev(iEnt, pev_spawnflags) & SF_SPAWN_START_OFF))
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
			{
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - Adding %d to possible spawn points.", __BINARY__, iEnt);
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - pev(iEnt, pev_spawnflags) %d", __BINARY__, pev(iEnt, pev_spawnflags));
			}
			ArrayPushCell(g_rgAvailableSpawnPoints, iEnt);
		}
	}

	iEnt = 0;
	while((iEnt = find_ent_by_class(iEnt, "info_player_deathmatch")))
	{
		if(pev_valid(iEnt) && !(pev(iEnt, pev_spawnflags) & SF_SPAWN_START_OFF))
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
			{
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - Adding %d to possible spawn points.", __BINARY__, iEnt);
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - pev(iEnt, pev_spawnflags) %d", __BINARY__, pev(iEnt, pev_spawnflags));
			}
			ArrayPushCell(g_rgAvailableSpawnPoints, iEnt);
		}
	}

	iEnt = 0;
	while((iEnt = find_ent_by_class(iEnt, "info_player_dm2")))
	{
		if(pev_valid(iEnt) && !(pev(iEnt, pev_spawnflags) & SF_SPAWN_START_OFF))
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
			{
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - Adding %d to possible spawn points.", __BINARY__, iEnt);
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - pev(iEnt, pev_spawnflags) %d", __BINARY__, pev(iEnt, pev_spawnflags));
			}
			ArrayPushCell(g_rgAvailableSpawnPoints, iEnt);
		}
	}

	iEnt = 0;
	while((iEnt = find_ent_by_class(iEnt, "info_player_coop")))
	{
		if(pev_valid(iEnt) && !(pev(iEnt, pev_spawnflags) & SF_SPAWN_START_OFF))
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
			{
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - Adding %d to possible spawn points.", __BINARY__, iEnt);
				server_print("[DEBUG] %s::ImSureThereAreSpawns() - pev(iEnt, pev_spawnflags) %d", __BINARY__, pev(iEnt, pev_spawnflags));
			}
			ArrayPushCell(g_rgAvailableSpawnPoints, iEnt);
		}
	}

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::ImSureThereAreSpawns() - We have %d possible spawn points.", __BINARY__, ArraySize(g_rgAvailableSpawnPoints));
}

/**
 * Creates and configures necessary game entities for plugin functionality.
 * Sets up respawn triggers, relay entities, and vote handling entities.
 *
 * @return void
 */
public SetupNeededEnts()
{
	g_hRespawnEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, RESPAWN_CLASSNAME));
	g_hRelayEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, RELAY_CLASSNAME));
	g_hGameOverEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, GAMEOVER_VOTE_CLASSNAME));
	g_hRestartEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, RESTART_CLASSNAME));
	g_hGameEndEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, GAMEEND_CLASSNAME));

	if(!g_hRespawnEnt || !g_hRelayEnt || !g_hGameOverEnt || !g_hRestartEnt || !g_hGameEndEnt || !pev_valid(g_hRespawnEnt) || !pev_valid(g_hRelayEnt) || !pev_valid(g_hGameOverEnt) || !pev_valid(g_hRestartEnt) || !pev_valid(g_hGameEndEnt))
    {
        server_print("[CRITICAL] %s::SetupNeededEnts() - Failed to create needed ents. Stopping.", __BINARY__);
        set_fail_state("Failed to create needed ents");
    }

	set_pev(g_hRespawnEnt, pev_targetname, RESPAWN_TARGETNAME);
	set_pev(g_hRespawnEnt, pev_spawnflags, SF_RESPAWN_DEADONLY | SF_RESPAWN_DONTMOVE);
	set_pev(g_hRespawnEnt, pev_flags, pev(g_hRespawnEnt, pev_flags) | FL_CUSTOMENTITY);
	dllfunc(DLLFunc_Spawn, g_hRespawnEnt);

	
	set_pev(g_hRelayEnt, pev_targetname, RELAY_TARGETNAME);
	set_pev(g_hRelayEnt, pev_flags, pev(g_hRelayEnt, pev_flags) | FL_CUSTOMENTITY);
	dllfunc(DLLFunc_Spawn, g_hRelayEnt);

	set_pev(g_hGameOverEnt, pev_message, "Game Over^nRestart map?");
	set_pev(g_hGameOverEnt, pev_frags, 20.0); //20 seconds to vote
	set_pev(g_hGameOverEnt, pev_health, 60.0); //60% needed to continue
	set_pev(g_hGameOverEnt, pev_target, RESTART_TARGETNAME);
	set_pev(g_hGameOverEnt, pev_netname, GAMEEND_TARGETNAME);
	set_pev(g_hGameOverEnt, pev_noise, GAMEEND_TARGETNAME);
	set_pev(g_hGameOverEnt, pev_targetname, GAMEOVER_VOTE_TARGETNAME);
	set_pev(g_hGameOverEnt, pev_flags, pev(g_hGameOverEnt, pev_flags) | FL_CUSTOMENTITY);
	dllfunc(DLLFunc_Spawn, g_hGameOverEnt);

	
	set_pev(g_hRestartEnt, pev_targetname, RESTART_TARGETNAME);
	set_pev(g_hRestartEnt, pev_flags, pev(g_hRestartEnt, pev_flags) | FL_CUSTOMENTITY);
	RegisterHam(Ham_Use, RESTART_CLASSNAME, "Event_RestartVoteOption_Use", true);
	dllfunc(DLLFunc_Spawn, g_hRestartEnt);

	
	set_pev(g_hGameEndEnt, pev_targetname, GAMEEND_TARGETNAME);
	set_pev(g_hGameEndEnt, pev_flags, pev(g_hGameEndEnt, pev_flags) | FL_CUSTOMENTITY);
	dllfunc(DLLFunc_Spawn, g_hGameEndEnt);
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
public client_disconnect(iClient)
{
	if(!g_bPluginEnabled)
		return;

	if(g_iSurvivalMode == SURVMODE_DISABLED)
		return;

	set_task(TECHNICAL_IMMEDIATE, "Task_ClientDisconnected_After", TASKID_CLIENTDISCONNECTED_AFTER+iClient);
}

public Task_ClientDisconnected_After(iTaskId)
{
	new iClient = iTaskId - TASKID_CLIENTDISCONNECTED_AFTER;

	//we don't do anything important, we can pass it without validation
	HandleLossOfPlayer(iClient);
}

public Event_GameEnd()
{
	g_bGameEnded = true;
}

#if AMXX_VERSION_NUM >= 183
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
	if(!g_bPluginEnabled)
		return;
	
	new iClient = get_pdata_ehandle(iWeaponId, m_pPlayer, g_iUnixDiff);
	g_bIsValidReviveBeacon[iClient] = true;
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
	if(!g_bPluginEnabled)
		return;

	new iClient = get_pdata_ehandle(iWeaponId, m_pPlayer, g_iUnixDiff);
	g_bIsValidReviveBeacon[iClient] = false;
}
#endif

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
	#if AMXX_VERSION_NUM < 183
	new iAlivePlayers = get_playersnum2(true);
	new iDeadPlayers = get_playersnum2(false);
	#else
	new iAlivePlayers = get_playersnum_ex(GetPlayers_ExcludeDead);
	new iDeadPlayers = get_playersnum_ex(GetPlayers_ExcludeAlive);
	#endif
	if(iAlivePlayers > 0 && g_bPluginEnabled)
	{
		if(g_iSurvivalMode == SURVMODE_WAVES && !g_bWaveIncoming && iDeadPlayers > 0)
		{
			if(!task_exists(TASKID_INITIALREINFORCEMENTS) || !g_bAllDead)
			{
				switch(g_iWaveMode)
				{
					case WAVEMODE_FIXED:
					{
						g_iRespawnTimeLeft = floatround(g_fWaveTime);
					}
					case WAVEMODE_PERPLAYER:
					{
						g_iRespawnTimeLeft = floatround(g_fWaveTime*(iAlivePlayers+iDeadPlayers));
					}
					case WAVEMODE_EXPONENTIAL:
					{
						new iPlayerCount = iAlivePlayers+iDeadPlayers;
						new Float:fBaseTime = g_fWaveTime; 

						g_iRespawnTimeLeft = 0;
						for(new x = 1; x <= iPlayerCount; x++)
						{
							g_iRespawnTimeLeft += floatround(fBaseTime);

							fBaseTime /= 2; 

							if(fBaseTime < g_iWaveMinTime)
								fBaseTime = g_iWaveMinTime*1.0; //prevents tag mismatch
						}
					}
				}
				g_bWaveIncoming = true;
				set_task(10.0, "CallForReinforcements", TASKID_INITIALREINFORCEMENTS);
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
 */
public Event_PlayerKilled_Post(iClient)
{
	if(!g_bPluginEnabled)
		return;

	if(g_iSurvivalMode == SURVMODE_DISABLED)
		return;
		
	HandleLossOfPlayer(iClient);
}

HandleLossOfPlayer(iClient)
{
	if(!g_bPluginEnabled)
		return;

	if(g_iSurvivalMode == SURVMODE_DISABLED)
		return;

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
	{
		if(is_user_connected2(iClient))
			server_print("[DEBUG] %s::Event_PlayerKilled_Post() - Called on %N", __BINARY__, iClient);
		else
			server_print("[DEBUG] %s::Event_PlayerKilled_Post() - Called on Player %d (Disconnected)", __BINARY__, iClient);
	}

	g_bIsValidReviveBeacon[iClient] = false;
	
	if(g_bSurvivalEnabled && !g_bGameEnded)
	{
		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] %s::Event_PlayerKilled_Post() - Survival is enabled", __BINARY__);

		#if AMXX_VERSION_NUM < 183
		new iAlivePlayers = get_playersnum2(true);
		#else
		new iAlivePlayers = get_playersnum_ex(GetPlayers_ExcludeDead);
		#endif

		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] %s::Event_PlayerKilled_Post() - iAlivePlayers is %d", __BINARY__, iAlivePlayers);

		if(iAlivePlayers == 0)
		{
			if(g_iPluginFlags & AMX_FLAG_DEBUG)
				server_print("[DEBUG] %s::Event_PlayerKilled_Post() - No more living players, ending game.", __BINARY__);

			client_print(0, print_chat, "No more players alive. Game over.");
			g_bAllDead = true;
			set_task(5.0, "TriggerVoteEntity", TASKID_TRIGGERVOTEENTITY);
		}
		else 
			CheckReinforcementConditions();
	}
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
		
		if(!task_exists(TASKID_REINFORCEMENTCOOLDOWN))
			set_task(g_fTimerAdvance, "Task_ReinforcementCooldown", TASKID_REINFORCEMENTCOOLDOWN);
		else
		{
			remove_task(TASKID_REINFORCEMENTCOOLDOWN);
			set_task(g_fTimerAdvance, "Task_ReinforcementCooldown", TASKID_REINFORCEMENTCOOLDOWN);
		}
	}
}

 /**
 * Pre-hook for spawn point activation. Check if the ent is not in the available spawn points
 * if it is, it means the spawn point is no longer available
 *
 * @return void
 */
public Event_SpawnActivation_Pre(iSpawnPoint)
{
	new szTargetName[MAX_NAME_LENGTH], szClassName[MAX_NAME_LENGTH];

	if(!pev_valid(iSpawnPoint))
		return HAM_IGNORED;

	pev(iSpawnPoint, pev_targetname, szTargetName, charsmax(szTargetName));
	pev(iSpawnPoint, pev_classname, szClassName, charsmax(szClassName));

	if(equali("info_target", szClassName)) //unsure why is it called on this
		return HAM_IGNORED;

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
	{
		server_print("[DEBUG] %s::Event_SpawnActivation_Pre() - Called on %d (%s)", __BINARY__, iSpawnPoint, szTargetName);
		server_print("[DEBUG] %s::Event_SpawnActivation_Pre() - We have %d possible spawn points.", __BINARY__, ArraySize(g_rgAvailableSpawnPoints));
	}

	#if AMXX_VERSION_NUM < 183
	new iSpawnPointIndex = -1;
	new iArraySize = ArraySize(g_rgAvailableSpawnPoints);
	for(new iIndex = 0; iIndex < iArraySize; iIndex++)
	{
		if(iSpawnPoint == ArrayGetCell(g_rgAvailableSpawnPoints, iIndex))
			iSpawnPointIndex = iIndex;
	}
	#else
	new iSpawnPointIndex = ArrayFindValue(g_rgAvailableSpawnPoints, iSpawnPoint);
	#endif

	if(iSpawnPointIndex == -1)
	{
		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] %s::Event_SpawnActivation_Pre() - %d didn't exist in the spawns, adding it. (it was activated)", __BINARY__, iSpawnPoint);
		ArrayPushCell(g_rgAvailableSpawnPoints, iSpawnPoint);
	}
	else 
	{
		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] %s::Event_SpawnActivation_Pre() - %d existed in spawns, removing it. (it was deactivated)", __BINARY__, iSpawnPoint);
		ArrayDeleteItem(g_rgAvailableSpawnPoints, iSpawnPointIndex);
	}

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::Event_SpawnActivation_Pre() - We have %d possible spawn points.", __BINARY__, ArraySize(g_rgAvailableSpawnPoints));

	if(ArraySize(g_rgAvailableSpawnPoints) == 0)
	{
		//no more spawns
		//saving last activation to create emergency spawns

		if(g_iPluginFlags & AMX_FLAG_DEBUG)
			server_print("[DEBUG] %s::Event_SpawnActivation_Pre() - No more spawns, activating emergency spawns.", __BINARY__);
			
		pev(iSpawnPoint, pev_targetname, g_szSpawnPointLastTargetName, charsmax(g_szSpawnPointLastTargetName));

		new iEnt = 0;
		while((iEnt = find_ent_by_tname(iEnt, g_szSpawnPointLastTargetName)))
		{
			if(pev_valid(iEnt))
			{
				new szClassName[MAX_NAME_LENGTH];
				pev(iEnt, pev_classname, szClassName, charsmax(szClassName));
				new Float:fOrigin[3];
				pev(iEnt, pev_origin, fOrigin);
				new iEmSpawn = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, szClassName));
				set_pev(iEmSpawn, pev_origin, fOrigin);
				set_pev(iEmSpawn, pev_targetname, EMERGENCY_SPAWN_TARGETNAME);
				dllfunc(DLLFunc_Spawn, iEmSpawn);
			}
		}

		g_bEmergencySpawning = true;
	}
	else if(g_bEmergencySpawning)
	{
		new iEnt = 0;
		//there are spawns now, and we were using emergency spawning
		while((iEnt = find_ent_by_tname(iEnt, EMERGENCY_SPAWN_TARGETNAME)))
			remove_entity(iEnt);

		g_bEmergencySpawning = false;
	}

	return HAM_IGNORED;
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
		server_print("[DEBUG] %s::Event_SpawnActivation_Post() - Called", __BINARY__);

	if(!g_bInfoActivated && g_bPluginEnabled && g_iSurvivalMode != SURVMODE_DISABLED && g_bSurvivalEnabled && g_bSurvivalActSpawn && !g_bAllDead)
	{
		g_bInfoActivated = true;
		RespawnAllPlayers();
		set_task(1.0, "Task_InfoActivatedCooldown", TASKID_INFOACTIVATEDCOOLDOWN);
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
	if(!g_bPluginEnabled || !g_bSurvivalEnabled || g_iSurvivalMode != SURVMODE_WAVES || !g_bWaveIncoming || task_exists(TASKID_INITIALREINFORCEMENTS) || g_bAllDead)
        return;

	#if AMXX_VERSION_NUM < 183
	new iAlivePlayers = get_playersnum2(true);
	new iDeadPlayers = get_playersnum2(false);
	#else
	new iAlivePlayers = get_playersnum_ex(GetPlayers_ExcludeDead);
	new iDeadPlayers = get_playersnum_ex(GetPlayers_ExcludeAlive);
	#endif

	if(iDeadPlayers == 0 || iAlivePlayers == 0)
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
	if(!g_bPluginEnabled || g_iSurvivalMode == SURVMODE_DISABLED || !g_bSurvivalEnabled || g_bAllDead)
        return;

	#if AMXX_VERSION_NUM < 183
	new iDeadPlayers = get_playersnum2(false);
	#else
	new iDeadPlayers = get_playersnum_ex(GetPlayers_ExcludeAlive);
	#endif

	if(iDeadPlayers >= 1)
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
	if(!g_bPluginEnabled || g_iSurvivalMode == SURVMODE_DISABLED || !g_bSurvivalEnabled || g_bAllDead)
        return;

	if(!g_bAllDead && g_bWaveIncoming)
	{
		#if AMXX_VERSION_NUM < 183
		new iDeadPlayers = get_playersnum2(false);
		#else
		new iDeadPlayers = get_playersnum_ex(GetPlayers_ExcludeAlive);
		#endif
		
		if(iDeadPlayers > 0)
		{
			client_print(0, print_chat, "Reinforcements have arrived!");
			RespawnAllPlayers();
		}
		g_bWaveIncoming = false;
	}
}

public Event_PlayerSpawn_Pre(iClient)
{
	if(!g_bPluginEnabled || g_iSurvivalMode == SURVMODE_DISABLED || !g_bSurvivalEnabled)
        return HAM_IGNORED;

	if(g_bAllDead)
		return HAM_SUPERCEDE; //prevent spawns if players are dead.
	
	//this seems unsafe, we should probably abort the vote somehow and let them spawn to continue playing?
	
	return HAM_IGNORED;
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
	if(!g_bPluginEnabled || g_iSurvivalMode == SURVMODE_DISABLED || !iClient)
		return HAM_IGNORED;

	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::Event_PlayerSpawn_Post() - Called on %N", __BINARY__,  iClient);

	//first spawn always considers player as dead (even in a post hook!), also functions like playercounts will return 0
	//so, for safety we will execute our logic in a little while after
	set_task(TECHNICAL_IMMEDIATE, "Event_PlayerSpawn_Post_After", TASKID_PLAYERSPAWN_POST_AFTER+get_user_userid(iClient));
	return HAM_IGNORED;
}

public Event_PlayerSpawn_Post_After(iTaskId)
{
	new iUserId = iTaskId - TASKID_PLAYERSPAWN_POST_AFTER;

	if(!iUserId)
		return;

	new iClient = find_player_ex(FindPlayer_MatchUserId, iUserId);

	if(!iClient || !is_user_connected2(iClient) || !is_user_alive(iClient))
		return; 

	SurvivalActivateNow();

	if(g_fSpawnProtectTime > 0.0) 
		SpawnProtectEnable(iClient);
}

/**
 * Enables temporary invulnerability for newly spawned players.
 * Applies visual effects and sets up protection removal timer.
 *
 * @param iClient Index of player to protect
 *
 * @return void
 */
public SpawnProtectEnable(iClient)
{
	if(is_user_connected2(iClient) && is_user_alive(iClient))
	{
		set_user_godmode(iClient, 1);
		set_user_rendering(iClient, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, g_iSpawnProtectShellThick);
		set_task(g_fSpawnProtectTime, "Task_SpawnProtectDisable", TASKID_SPAWNPROTECT+iClient);
	}
}

SurvivalActivateNow()
{
	if(g_iSurvivalMode != SURVMODE_DISABLED)
	{
		#if AMXX_VERSION_NUM < 183
		new iPlayersNum = get_playersnum();
		#else
		new iPlayersNum = get_playersnum_ex();
		#endif
		if(g_iPluginFlags & AMX_FLAG_DEBUG)
		{
			server_print("[DEBUG] %s::SurvivalActivateNow() - g_iSurvivalMode is %d", __BINARY__, g_iSurvivalMode);
			server_print("[DEBUG] %s::SurvivalActivateNow() - g_iSurvivalMinPlayers is %d", __BINARY__, g_iSurvivalMinPlayers);
			server_print("[DEBUG] %s::SurvivalActivateNow() - iPlayersNum is %d", __BINARY__, iPlayersNum);
			server_print("[DEBUG] %s::SurvivalActivateNow() - g_bSurvivalEnabled is %b", __BINARY__, g_bSurvivalEnabled);
		}

		if(!g_bSurvivalEnabled && iPlayersNum >= g_iSurvivalMinPlayers)
		{
			if(!task_exists(TASKID_ENABLESURVIVAL))
			{
				if(g_iPluginFlags & AMX_FLAG_DEBUG)
					server_print("[DEBUG] %s::SurvivalActivateNow() - I want to enable survival mode", __BINARY__);
					
				new iEnableSurvivalTime = floatround(g_fSurvivalStartDelay);
				client_print(0, print_chat, "Enabling survival mode in %d seconds", iEnableSurvivalTime);
				server_print("Enabling survival mode in %d seconds", iEnableSurvivalTime);
				client_print(0, print_center, "Enabling survival mode in %d seconds", iEnableSurvivalTime);
				set_task(g_fSurvivalStartDelay, "Task_EnableSurvival", TASKID_ENABLESURVIVAL);
			}
		}
		else if(!g_bSurvivalEnabled)
		{
			client_print(0, print_chat, "Not enough players to activate survival mode. Minimum %d", g_iSurvivalMinPlayers);

			if(task_exists(TASKID_ENABLESURVIVAL))
				remove_task(TASKID_ENABLESURVIVAL);
		}
	}
}

/**
 * Enables survival mode.
 * Sets up necessary game settings and notifies players.
 *
 * @return void
 */
public Task_EnableSurvival()
{
	#if AMXX_VERSION_NUM < 183
	new iPlayersNum = get_playersnum();
	#else
	new iPlayersNum = get_playersnum_ex();
	#endif
	if(iPlayersNum > 0)
	{
		RespawnAllPlayers();
		client_print(0, print_chat, "Survival mode enabled. No more respawning allowed!");
		client_print(0, print_center, "Survival mode enabled.^nNo more respawning allowed!");
		set_pcvar_bool(g_cvarObserverMode, true);
		set_pcvar_bool(g_cvarObserverCyclic, true);
		g_bSurvivalEnabled = true;
	}
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
	new iClient = iTaskId-TASKID_SPAWNPROTECT;
	if(!is_user_connected2(iClient))
		return;
	else
	{
		set_user_godmode(iClient, 0);
		set_user_rendering(iClient, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	}
}

#if AMXX_VERSION_NUM >= 183
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
		server_print("[DEBUG] %s::Event_PlayerRevived_Post() - Called on client %d", __BINARY__, iClient);

	#if AMXX_VERSION_NUM < 183
	new iDeadPlayers = get_playersnum2(false);
	#else
	new iDeadPlayers = get_playersnum_ex(GetPlayers_ExcludeAlive);
	#endif

	if(iDeadPlayers == 0)
		g_bWaveIncoming = false;

	if(g_fSpawnProtectTime > 0.0)
	{
		if(pev_valid(iClient) && !task_exists(TASKID_SPAWNPROTECT+iClient))
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
				|| iOther == iClient
				|| !pev_valid(iClient))
					continue;

				new Float:fOtherOrigin[3];
				pev(iOther, pev_origin, fOtherOrigin);
				set_pev(iClient, pev_origin, fOtherOrigin);
				set_task(0.5, "Task_UnstuckPlayer", TASKID_UNSTUCK+iClient);
				break;
			}
			SpawnProtectEnable(iClient);
		}
	}

	return HAM_IGNORED;
}
#endif

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
	new iClient = iTaskId-TASKID_UNSTUCK;
	if(is_user_connected2(iClient) && is_user_alive(iClient)) 
	{
		static Float:fClientOrigin[3], iHullType;
		static Float:fClientMins[3];
		static Float:fDesiredOrigin[3];
		pev(iClient, pev_origin, fClientOrigin);
		iHullType = pev(iClient, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;
		if(!IsHullVacant(fClientOrigin, iHullType, iClient) && !get_user_noclip(iClient) && !(pev(iClient,pev_solid) & SOLID_NOT)) 
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
		server_print("[DEBUG] %s::Command_RespawnDeadPlayers() - Called", __BINARY__);
		server_print("[DEBUG] %s::Command_RespawnDeadPlayers() - iClient is %d", __BINARY__, iClient);
		server_print("[DEBUG] %s::Command_RespawnDeadPlayers() - iLevel is %d", __BINARY__, iLevel);
		server_print("[DEBUG] %s::Command_RespawnDeadPlayers() - iCommandId is %d", __BINARY__, iCommandId);
	}

	//this condition fixes a bug where the command Command_RespawnDeadPlayers() gets called randomly
	//unsure what is causing it 
	if(iClient == 0 && iLevel == -520167424 && iCommandId == 0)
		return PLUGIN_HANDLED;

	if (!cmd_access(iClient, iLevel, iCommandId, 1))
		return PLUGIN_HANDLED;

	#if AMXX_VERSION_NUM < 183
	new iDeadPlayers = get_playersnum2(false);
	#else
	new iDeadPlayers = get_playersnum_ex(GetPlayers_ExcludeAlive);
	#endif

	if(iDeadPlayers == 0)
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
	if(pev_valid(g_hRespawnEnt) && pev_valid(g_hRelayEnt))
		ExecuteHamB(Ham_Use, g_hRespawnEnt, g_hRelayEnt, g_hRelayEnt, 0, 0.0);
	else
		server_print("[WARNING] %s::RespawnAllPlayers() - Not possible to respawn because basic entities are not valid", __BINARY__);
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
 * Registers damage event hooks for all monster entities.
 * Used to track combat activity for timer advancement.
 *
 * @return void
 */
RegisterMonsterHooks()
{
	if(g_iPluginFlags & AMX_FLAG_DEBUG)
		server_print("[DEBUG] %s::RegisterMonsterHooks() - Called", __BINARY__);

	#if AMXX_VERSION_NUM < 183
	for(new iCursor; iCursor < sizeof g_szMonsterList; iCursor++)
		RegisterHam(Ham_TakeDamage, g_szMonsterList[iCursor], "Event_GetDamagePoints_Post", true);
	#else 
	for(new iCursor; iCursor < sizeof g_szMonsterList; iCursor++)
		RegisterHam(Ham_SC_GetDamagePoints, g_szMonsterList[iCursor], "Event_GetDamagePoints_Post", true);
	#endif
}

#if AMXX_VERSION_NUM < 183
stock get_playersnum2(bool:bAlive)
{
    new iCount = 0;
    for(new iClient=1; iClient <= MaxClients;iClient++)
    {
        if(is_user_connected2(iClient) && ( (bAlive && is_user_alive(iClient)) || (!bAlive && !is_user_alive(iClient)) ))
            iCount++;
    }
    return iCount;
}
#endif

stock bool:is_user_connected2(iClient)
{
    #if AMXX_VERSION_NUM < 183
    return is_user_connected(iClient) == 1;
    #else
    if(IsValidUserIndex(iClient) && pev_valid(iClient) == 2)
        return bool:ExecuteHam(Ham_SC_Player_IsConnected, iClient);
    else
        return false;
    #endif
}