# Intrusive Thoughts
## License:
This project is licensed under the GNU Affero GPL v3. I, Hana Nova, am the sole contributor to this project. Any external contributions will only be accepted with a waiver handing over all rights to the contributed code back to the project owner.

This does not mean you can just use this code without making your changes public, in fact you must make them public for free. But it does mean that I will not include your changes in this main repository without signing a contributor agreement.

## Instructions:

Create a cube and put one copy of every script in the Slave directory into it. Then add as many rlv relay client scripts as you need device support. Make sure that the client script has 'client' in the name. Add as many transferrable animations as you want into it. Reset all the scripts. This is your slave device.

Create a hud. You will have to add button and indicators as specified in the intrusive-thoughts-ui.lsl file, and as used in the other scripts. Then add one copy of every script in the Master directory into it, plus as many relay client scripts you need. Add the "!config" notecard, plus as many notecards as you want 'appliers' for your subs, examples of these are in the Configuration NC directory. Reset the scripts. This is your master device.

Create an invisible cylinder (blank texture but alpha 100%) named "ball" and drop the contents of the Ball directory into it. For the carrier, you will have to create a mesh stomach and look at the scripts in the carrier directory for information on how it should be built. Then drop this ball and carrier into your master device. Your master device is now complete.

Make two invisible prims, and drop one of the scripts in the Translator directory in each. One will be a universal translator while the other one will be tuned to one slave device.

## Other scripts:

The leashhandle script can be dropped in the linked prim of a leash holder that should be the anchor for the leash particles.

The furniture script can be dropped in furniture for objectification needs.

Art assets are provided as used in my personal implementation of this HUD.