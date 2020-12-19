#include <IT/globals.lsl>
float interval = 60.0;
 
default 
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    state_entry() 
    {
        integer loop;
        string watchee;
        llSleep(interval/2);
        for (loop = llGetInventoryNumber(INVENTORY_SCRIPT) -1; loop > -1; --loop) 
        {
            watchee = llGetInventoryName(INVENTORY_SCRIPT, loop);
            if(llGetInventoryType(watchee) == INVENTORY_SCRIPT) 
            {
                if(!llGetScriptState(watchee)) 
                {
                    if(watchee != llGetScriptName()) 
                    {
                        llResetOtherScript(watchee);
                        llSetScriptState(watchee, TRUE);
                        llInstantMessage((key)llGetObjectDesc(), "The script [" + watchee + "] owned by secondlife:///app/agent/" + (string)llGetOwner() + "/about has crashed and has been restarted. You will need to reconfigure the device in their vicinity.");
                        llDialog(llGetOwner(), "The script [" + watchee + "] has crashed and has been restarted. Your device has been reset and your owner will need to reconfigure or replace it.", ["OK"], -996543782);
                        llMessageLinked(LINK_SET, API_RESET, "", llGetOwner());
                    }
                }
            }
        }
        llSleep(interval/2);
        llResetScript();
    }

    on_rez(integer param) 
    {
        llResetScript();
    }
}