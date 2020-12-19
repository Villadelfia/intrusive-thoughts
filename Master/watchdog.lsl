#include <IT/globals.lsl>
float interval = 60.0;
 
default 
{
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
                        llDialog(llGetOwner(), "The script [" + watchee + "] has crashed and has been restarted.", ["OK"], -996543782);
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