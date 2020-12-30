#define MANTRA_CHANNEL   -216684563
#define PING_CHANNEL     -216684564
#define DIALOG_CHANNEL   -219755312
#define RLV_CHANNEL       166845630
#define VOICE_CHANNEL     166845631
#define HUD_SPEAK_CHANNEL 166845632
#define RLV_CHECK_CHANNEL 166845633
#define GAZE_CHAT_CHANNEL 166845634
#define SPEAK_CHANNEL     166845635
#define LEASH_CHANNEL     166845636
#define HOME_HUD_CHANNEL  166845637
#define RLVRC           -1812221819
#define COMMAND_CHANNEL           1
#define GAZE_CHANNEL              1
#define BALL_CHANNEL              8
#define API_RESET                -1
#define API_SELF_DESC            -2
#define API_SELF_SAY             -3
#define API_SAY                  -4
#define API_ONLY_OTHERS_SAY      -5
#define API_BLIND_TOGGLE         -6
#define API_DEAF_TOGGLE          -7
#define API_MUTE_TOGGLE          -8
#define API_FOCUS_TOGGLE         -9
#define API_DOTP                -10
#define API_TPOK                -11
#define API_DISABLE             -12
#define API_ENABLE              -13
#define API_STARTUP_DONE        -14
#define API_CONFIG_DATA         -15
#define API_GIVE_TP_MENU        -16
#define API_CLOSEST_TO_CAM      -17
#define API_RLV_SET_SRC         -18
#define API_RLV_CLR_SRC         -19
#define API_RLV_HANDLE_CMD      -20
#define API_RLV_SAFEWORD        -21
#define API_CLOSEST_OBJ         -22
#define API_FILL_FACTOR         -23
#define API_GIVE_VORE_MENU      -24
#define API_SET_LOCK            -25
string VERSION_S = "IT-Slave v1.6";
string VERSION_C = "IT-Cntrl v1.6";

integer startswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, llStringLength(needle), 0x7FFFFFF0) == needle;
}

integer contains(string haystack, string needle)
{
    return 0 <= llSubStringIndex(haystack, needle);
}

integer endswith(string haystack, string needle)
{
    return llDeleteSubString(haystack, 0x8000000F, ~llStringLength(needle)) == needle;
}

integer getstringbytes(string msg)
{
    return (llStringLength((string)llParseString2List(llStringToBase64(msg), ["="], [])) * 3) >> 2;
}

string slurl()
{
    vector pos = llGetPos();
    return "http://maps.secondlife.com/secondlife/" + llEscapeURL(llGetRegionName()) + "/" + (string)llRound(pos.x) + "/" + (string)llRound(pos.y) + "/" + (string)llRound(pos.z) + "/";
}

string slurlp(string region, string x, string y, string z)
{
    return "http://maps.secondlife.com/secondlife/" + llEscapeURL(region) + "/" + x + "/" + y + "/" + z + "/";
}

string strreplace(string source, string pattern, string replace) 
{
    while (llSubStringIndex(source, pattern) > -1) 
    {
        integer len = llStringLength(pattern);
        integer pos = llSubStringIndex(source, pattern);
        if (llStringLength(source) == len) { source = replace; }
        else if (pos == 0) { source = replace+llGetSubString(source, pos+len, -1); }
        else if (pos == llStringLength(source)-len) { source = llGetSubString(source, 0, pos-1)+replace; }
        else { source = llGetSubString(source, 0, pos-1)+replace+llGetSubString(source, pos+len, -1); }
    }
    return source;
}

list orderbuttons(list buttons)
{
    return llList2List(buttons, -3, -1) + llList2List(buttons, -6, -4)
         + llList2List(buttons, -9, -7) + llList2List(buttons, -12, -10);
}

integer random(integer min, integer max)
{
    return min + (integer)(llFrand(max - min + 1));
}

string attachpointtotext(integer p)
{
    if(p == ATTACH_HEAD)                  return "Skull";
    else if(p == ATTACH_NOSE)             return "Nose";
    else if(p == ATTACH_MOUTH)            return "Nose";
    else if(p == ATTACH_FACE_TONGUE)      return "Tongue";
    else if(p == ATTACH_CHIN)             return "Chin";
    else if(p == ATTACH_FACE_JAW)         return "Jaw";
    else if(p == ATTACH_LEAR)             return "Left Ear";
    else if(p == ATTACH_REAR)             return "Right Ear";
    else if(p == ATTACH_FACE_LEAR)        return "Alt Left Ear";
    else if(p == ATTACH_FACE_REAR)        return "Alt Right Ear";
    else if(p == ATTACH_LEYE)             return "Left Eye";
    else if(p == ATTACH_REYE)             return "Right Eye";
    else if(p == ATTACH_FACE_LEYE)        return "Alt Left Eye";
    else if(p == ATTACH_FACE_REYE)        return "Alt Right Eye";
    else if(p == ATTACH_NECK)             return "Neck";
    else if(p == ATTACH_LSHOULDER)        return "Left Shoulder";
    else if(p == ATTACH_RSHOULDER)        return "Right Shoulder";
    else if(p == ATTACH_LUARM)            return "L Upper Arm";
    else if(p == ATTACH_RUARM)            return "R Upper Arm";
    else if(p == ATTACH_LLARM)            return "L Lower Arm";
    else if(p == ATTACH_RLARM)            return "R Lower Arm";
    else if(p == ATTACH_LHAND)            return "Left Hand";
    else if(p == ATTACH_RHAND)            return "Right Hand";
    else if(p == ATTACH_LHAND_RING1)      return "Left Ring Finger";
    else if(p == ATTACH_RHAND_RING1)      return "Right Ring Finger";
    else if(p == ATTACH_LWING)            return "Left Wing";
    else if(p == ATTACH_RWING)            return "Right Wing";
    else if(p == ATTACH_CHEST)            return "Chest";
    else if(p == ATTACH_LEFT_PEC)         return "Left Pec";
    else if(p == ATTACH_RIGHT_PEC)        return "Right Pec";
    else if(p == ATTACH_BELLY)            return "Stomach";
    else if(p == ATTACH_BACK)             return "Spine";
    else if(p == ATTACH_TAIL_BASE)        return "Tail Base";
    else if(p == ATTACH_TAIL_TIP)         return "Tail Tip";
    else if(p == ATTACH_AVATAR_CENTER)    return "Avatar Center";
    else if(p == ATTACH_PELVIS)           return "Pelvis";
    else if(p == ATTACH_GROIN)            return "Groin";
    else if(p == ATTACH_LHIP)             return "Left Hip";
    else if(p == ATTACH_RHIP)             return "Right Hip";
    else if(p == ATTACH_LULEG)            return "L Upper Leg";
    else if(p == ATTACH_RULEG)            return "R Upper Leg";
    else if(p == ATTACH_RLLEG)            return "R Lower Leg";
    else if(p == ATTACH_LLLEG)            return "L Lower Leg";
    else if(p == ATTACH_LFOOT)            return "Left Foot";
    else if(p == ATTACH_RFOOT)            return "Right Foot";
    else if(p == ATTACH_HIND_LFOOT)       return "Left Hind Foot";
    else if(p == ATTACH_HIND_RFOOT)       return "Right Hind Foot";
    else if(p == ATTACH_HUD_CENTER_2)     return "HUD Center 2";
    else if(p == ATTACH_HUD_TOP_RIGHT)    return "HUD Top Right";
    else if(p == ATTACH_HUD_TOP_CENTER)   return "HUD Top";
    else if(p == ATTACH_HUD_TOP_LEFT)     return "HUD Top Left";
    else if(p == ATTACH_HUD_CENTER_1)     return "HUD Center";
    else if(p == ATTACH_HUD_BOTTOM_LEFT)  return "HUD Bottom Left";
    else if(p == ATTACH_HUD_BOTTOM)       return "HUD Bottom";
    else if(p == ATTACH_HUD_BOTTOM_RIGHT) return "HUD Bottom Right";
    else                                  return "Unknown";
}