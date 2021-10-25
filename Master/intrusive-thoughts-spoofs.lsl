#include <IT/globals.lsl>
integer configured = FALSE;
string objectifyDefaultCaptureSpoof;
string objectifyDefaultReleaseSpoof;
string objectifyDefaultPutonSpoof;
string objectifyDefaultPutdownSpoof;
string voreCaptureSpoof;
string voreReleaseSpoof;
string possessCaptureSpoof;
string possessReleaseSpoof;
list customCaptureSpoofNames = [];
list customCaptureSpoofs = [];
list customReleaseSpoofNames = [];
list customReleaseSpoofs = [];


default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CONFIG_DONE) 
        {
            configured = TRUE;
        }
        else if(num == M_API_CONFIG_DATA)
        {
            if(configured)
            {
                customCaptureSpoofNames = [];
                customCaptureSpoofs = [];
                customReleaseSpoofNames = [];
                customReleaseSpoofs = [];
                configured = FALSE;
            }
            if(str == "capture")        objectifyDefaultCaptureSpoof = (string)id;
            else if(str == "release")   objectifyDefaultReleaseSpoof = (string)id;
            else if(str == "puton")     objectifyDefaultPutonSpoof = (string)id;
            else if(str == "putdown")   objectifyDefaultPutdownSpoof = (string)id;
            else if(str == "vore")      voreCaptureSpoof = (string)id;
            else if(str == "unvore")    voreReleaseSpoof = (string)id;
            else if(str == "possess")   possessCaptureSpoof = (string)id;
            else if(str == "unpossess") possessReleaseSpoof = (string)id;
            else if(startswith(str, "capture:")) 
            {
                customCaptureSpoofNames += [llToLower(llGetSubString(str, 8, -1))];
                customCaptureSpoofs += [(string)id];
            }
            else if(startswith(str, "release:")) 
            {
                customReleaseSpoofNames += [llToLower(llGetSubString(str, 8, -1))];
                customReleaseSpoofs += [(string)id];
            }
        }
        else if(num == M_API_SPOOF)
        {
            list params = llParseString2List((string)id, ["|||"], []);
            string me  = (string)params[0];
            string obj = (string)params[1];
            string vic = (string)params[2];
            string tar = (string)params[3];
            string using = "";
            if(str == "objcapture")
            {
                integer where = llListFindList(customCaptureSpoofNames, [llToLower(obj)]);
                if(where != -1) using = llList2String(customCaptureSpoofs, where);
                else            using = objectifyDefaultCaptureSpoof;
            }
            else if(str == "objrelease")
            {
                integer where = llListFindList(customReleaseSpoofNames, [llToLower(obj)]);
                if(where != -1) using = llList2String(customReleaseSpoofs, where);
                else            using = objectifyDefaultReleaseSpoof;
            }
            else if(str == "objputdown")     using = objectifyDefaultPutdownSpoof;
            else if(str == "objputon")       using = objectifyDefaultPutonSpoof;
            else if(str == "vorecapture")    using = voreCaptureSpoof;
            else if(str == "vorerelease")    using = voreReleaseSpoof;
            else if(str == "possesscapture") using = possessCaptureSpoof;
            else if(str == "possessrelease") using = possessReleaseSpoof;

            string spoof;
            spoof = llDumpList2String(llParseStringKeepNulls(using, ["%ME%"], []), me);
            spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%OBJ%"], []), obj);
            spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%VIC%"], []), vic);
            spoof = llDumpList2String(llParseStringKeepNulls(spoof, ["%TAR%"], []), tar);
            llSay(0, spoof);
        }
    }
}