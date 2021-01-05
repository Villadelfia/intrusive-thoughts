#define IT_PLUGIN_REGISTER    -8000 // PLUGIN -> IT
#define IT_PLUGIN_RESPONSE    -8001 // IT -> PLUGIN
#define IT_PLUGIN_OWNERSAY    -8002 // PLUGIN -> IT
#define IT_PLUGIN_INFOREQUEST -8003 // IT -> PLUGIN
#define IT_PLUGIN_COMMAND     -8004 // IT -> PLUGIN
#define IT_PLUGIN_ALLOWSLAVE  -8005 // PLUGIN -> IT
#define IT_PLUGIN_ACK         -8006 // IT -> PLUGIN
#define IT_PLUGIN_LOCK        -8007 // IT -> PLUGIN
#define IT_PLUGIN_OBJECT      -8008 // IT -> PLUGIN
#define IT_PLUGIN_DESCRIPTION -8009 // PLUGIN -> IT

string chatcommand = "setgroup";
integer enabled = TRUE;
integer retryct = 0;
key assigneduuid = NULL_KEY;

default
{
    state_entry()
    {
        llSleep(5.0);
        llMessageLinked(LINK_SET, IT_PLUGIN_REGISTER, llGetScriptName(), chatcommand);
    }
    
    changed(integer change)
    {
        if(change & CHANGED_TELEPORT)
        {
            if(enabled) llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0) + "=force");
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        // Register response.
        if(num == IT_PLUGIN_RESPONSE)
        {
            list args = llParseString2List(str, [","], []);

            // If we're being targeted by the call.
            if((string)args[1] == llGetScriptName() && (string)args[2] == chatcommand)
            {
                assigneduuid = id;

                // If the command was taken, try again with a number appended.
                if(assigneduuid == NULL_KEY)
                {
                    chatcommand = "setgroup" + (string)retryct;
                    ++retryct;
                    llMessageLinked(LINK_SET, IT_PLUGIN_REGISTER, llGetScriptName(), chatcommand);
                }

                // Otherwise, give a short description of the command.
                else
                {
                    llMessageLinked(LINK_SET, IT_PLUGIN_DESCRIPTION, "Set your group to the landgroup on teleport", assigneduuid);
                }
            }
        }

        // The system wants plugin information.
        else if(num == IT_PLUGIN_INFOREQUEST)
        {
            // If not aimed at us, return.
            if(id != assigneduuid) return;

            // Otherwise, respond.
            string text = "Land group plugin: Will set your land group whenever you teleport if enabled. Click [%APPCOMMAND%" + llEscapeURL(" enable") + " here] to enable or click [%APPCOMMAND%" + llEscapeURL(" disable") + " here] to disable.";
            llMessageLinked(LINK_SET, IT_PLUGIN_OWNERSAY, text, assigneduuid);
        }

        // The system wants us to execute a command.
        else if(num == IT_PLUGIN_COMMAND)
        {
            // If not aimed at us, return.
            key uuid = (key)llList2String(llParseString2List(str, [","], []), 1);
            if(uuid != assigneduuid) return;

            if((string)id == "enable")
            {
                enabled = TRUE;
                llMessageLinked(LINK_SET, IT_PLUGIN_OWNERSAY, "Land group setting enabled.", assigneduuid);
            }
            else if((string)id == "disable")
            {
                enabled = FALSE;
                llMessageLinked(LINK_SET, IT_PLUGIN_OWNERSAY, "Land group setting disabled.", assigneduuid);
            }
        }
    }
}