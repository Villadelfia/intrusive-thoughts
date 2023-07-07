// The Haute Cuisine part of IT is intentionally more complex and a bit hidden
// compared to all of the regular functions. It's meant for advanced users.
// This includes even things like IT not locking when the pred has an active
// prey. Because of its advanced nature and the requirement of modding and setup
// all the scripts involved in the subsystem are included with modify permissions
// but they will require setting up a local repository of the IT codebase from
// https://github.com/Villadelfia/intrusive-thoughts so that #include directives
// will work.
//
// Where in the normal vore subsystem the carrier is just called 'carrier', in
// the haute cuisine system we support multiple carriers, which are scanned for
// in inventory change change events and on boot. Any object which is named
// like 'hccarrier-name' is treated as a valid carrier and it is the
// responsibility of the modder to verify that it indeed is one.
//
// In this name, name is the name that shall be used in the commands for the hc
// subsystem, this name cannot contain spaces or dashes.
//
// Unlike in the regular vore system, the carrier itself is not responsible for
// capturing and restricting the prey. This is delegated to the hccapture object.
//
// The general workflow for eating someone using hc thus becomes:
//  - Check if there is a locked avatar. If not, cancel.
//  - Check if the requested carrier exists. If not, cancel.
//  - Check if the requested carrier is already rezzed. If not, do so.
//  - Rez the hccapture object and inform it of three things (and only three things):
//    - Who to capture by uuid.
//    - Which carrier to request more information from by uuid.
//    - Which offset to float beneath the pred.
//  - At this point, the hc subsystem is only responsible for ferrying commands
//    to the carriers and capturers and to check whether they still exist. If not,
//    it shall update its internal lists. The carriers and capturers will use their
//    description fields to communicate all the needed data to the hud to facilitate
//    bookkeeping.
//  - Everything else is interrogated between the carriers and capturers and is
//    documented in those scripts.

#include <IT/globals.lsl>
#include <IT/LibNRI.lsl>

integer configured = FALSE;
key lockedavatar = NULL_KEY;
string lockedname = "";

// The carriers list is a list of 5-tuples:
//  - full object name.
//  - uuid of currently rezzed instance of the carrier.
//  - current z-offset under pred.
//  - current z-scale.
//  - comma-delimited list of uuid's currently known to be following said carrier.
#define CARRIER_STRIDE 5
list carriers = [];
integer carrierLength = 0;

string carrierNameForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return "";
    return llList2String(carriers, (idx*CARRIER_STRIDE));
}

key carrierKeyForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return NULL_KEY;
    return llList2Key(carriers, (idx*CARRIER_STRIDE)+1);
}

float carrierOffsetForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return -1.0;
    return llList2Float(carriers, (idx*CARRIER_STRIDE)+2);
}

float carrierZScaleForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return -1.0;
    return llList2Float(carriers, (idx*CARRIER_STRIDE)+3);
}

list carrierCarryingForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return [];
    return llParseString2List(llList2String(carriers, (idx*CARRIER_STRIDE)+4), [","], []);
}

checkCarriers() {
    // Check if there's any new carriers...
    integer i = 0;
    integer l = llGetInventoryNumber(INVENTORY_OBJECT);
    for(i = 0; i < l; ++i) {
        // Check every object if it's the correct name, and is not listed yet.
        string oName = llGetInventoryName(INVENTORY_OBJECT, i);
        if(nriStringStartsWith(oName, "hccarrier-") && llListFindList(carriers, [oName]) == -1) {
            // Check if it has the correct amount of elements.
            list elements = llParseString2List(oName, ["-"], []);
            if(llGetListLength(elements) == 2) {
                // Add it to the list.
                carriers += [oName, NULL_KEY, 0.0, 0.0, ""];
            }
        }
    }
    carrierLength = llGetListLength(carriers);

    // Check if there's carriers missing from inventory...
    l = carrierLength / CARRIER_STRIDE;
    while(~--l) {
        string cName = carrierNameForIndex(l);
        if(llGetInventoryType(cName) != INVENTORY_OBJECT) {
            // If it's both missing, and we don't have a residual copy rezzed, purge it.
            key cKey = carrierKeyForIndex(l);
            list cCarrying = carrierCarryingForIndex(l);
            if(cKey == NULL_KEY && cCarrying == []) {
                carriers = llDeleteSubList(carriers, l * CARRIER_STRIDE, ((l+1)*CARRIER_STRIDE)-1);
            }
        }
    }
    carrierLength = llGetListLength(carriers);

    // Check if all non-null uuids are still present.
    l = carrierLength / CARRIER_STRIDE;
    for(i = 0; i < l; ++i) {
        key cKey = carrierKeyForIndex(i);
        if(cKey != NULL_KEY && llList2Vector(llGetObjectDetails(cKey, [OBJECT_POS]), 0) == ZERO_VECTOR) {
            carriers = llListReplaceList(carriers, [NULL_KEY, -1.0, -1.0, ""], (i*CARRIER_STRIDE)+1, (i*CARRIER_STRIDE)+4);
        }
    }
}

reflowCarriers() {
    // Reflow all the carriers under the pred.
    float runningOffset = 5.0;
    integer i = 0;
    integer l = carrierLength / CARRIER_STRIDE;
    for(i = 0; i < l; ++i) {
        // Check all carriers and see if they exist.
        key cKey = carrierKeyForIndex(i);
        list cAABB = llGetBoundingBox(cKey);
        if(cAABB != []) {
            // Calculate their size and where they should be.
            vector cCurSize = llList2Vector(cAABB, 1) - llList2Vector(cAABB, 0);
            float cCurZ = cCurSize.z;
            float cPrevZ = carrierZScaleForIndex(i);
            float cCurOffset = runningOffset + (cCurZ / 2.0);
            float cPrevOffset = carrierOffsetForIndex(i);
            // Communicate and save the new offset and size if it changed.
            if(cCurZ != cPrevZ || cCurOffset != cPrevOffset) {
                carriers = llListReplaceList(carriers, [cCurOffset, cCurZ], (i*CARRIER_STRIDE)+2, (i*CARRIER_STRIDE)+3);
                llRegionSayTo(cKey, MANTRA_CHANNEL, "hc_zoffset " + (string)cCurOffset);
            }
            // Add this z-size to the running start point.
            runningOffset += cCurZ;
        }
    }
}

integer ownCapturer(key uuid) {
    integer l = carrierLength / CARRIER_STRIDE;
    integer i = 0;
    for(i = 0; i < l; ++i) {
        list cCarrying = carrierCarryingForIndex(i);
        integer k = llGetListLength(cCarrying);
        while(~--k) {
            key cCapturer = (key)llList2String(cCarrying, k);
            if(cCapturer == uuid) return TRUE;
        }
    }
    return FALSE;
}

default {
    state_entry() {
        llListen(HC_CHANNEL, "", NULL_KEY, "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
    }

    attach(key id) {
        if(id == NULL_KEY) llSetTimerEvent(0.0);
    }

    listen(integer c, string n, key id, string m) {
        if(!configured) return;

        if(c == HC_CHANNEL) {
            if(!ownCapturer(id)) return;
            llSetObjectName(llList2String(llParseString2List(m, ["|||"], []), 0));
            llSay(0, llList2String(llParseString2List(m, ["|||"], []), 1));
            llSetObjectName(master_base);
        } else if(c == MANTRA_CHANNEL) {
            // Handle mantra
        } else if(c == COMMAND_CHANNEL) {
            if(llGetOwnerKey(id) != llGetOwner()) return;
            if(nriParseCommand(m, "hc", "!") == "!") return;
            // Handle hc commands.
        }
    }

    link_message(integer sender_num, integer num, string str, key id) {
        if(num == M_API_CONFIG_DONE) {
            llSetTimerEvent(5.0);
            configured = TRUE;
        } else if(num == M_API_CONFIG_DATA) {
            configured = FALSE;
        } else if(num == M_API_LOCK) {
            lockedavatar = id;
            lockedname = str;
        }
    }

    timer() {
        llSetTimerEvent(0.0);
        if(!configured) return;
        checkCarriers();
        reflowCarriers();
        llSetTimerEvent(5.0);
    }
}
