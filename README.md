# Welcome to CC-TurtleCrafter
A program designed for turtles in computercraft mod for minecraft
With this, you can deploy turtles as static autocrafters in seconds

## Requirements
- Minecraft 1.20.1 (Unless the key mod gets updated)
- Fabric loader:

	[Fabric page](https://fabricmc.net/use/installer/)
- Fabric API:

	[Curseforge](https://www.curseforge.com/minecraft/mc-mods/fabric-api/files/all?page=1&pageSize=20&version=1.20.1)  
	[Modrinth](https://modrinth.com/mod/fabric-api/versions?g=1.20.1)
- Computercraft (CC: Tweaked):

  [Curseforge](https://www.curseforge.com/minecraft/mc-mods/cc-tweaked/files/all?page=1&pageSize=20&version=1.20.1&gameVersionTypeId=4)  
  [Fabric](https://modrinth.com/mod/cc-tweaked/versions?l=fabric&g=1.20.1)
- Unlimited peripheral works (This is the key mod that makes all of this work):  
  	The only version that works is the v1.20.1-1.4.4-pre.1 pre-release (Only available on github)
  
	[Github](https://github.com/SirEdvin/UnlimitedPeripheralWorks/releases)  
- Peripheralium:  
	The only version that works is the v1.20.1-0.6.16-pre.3 pre-release (Only available on github)

	[Github](https://github.com/SirEdvin/Peripheralium/releases)  

## Installation
Links for those who already know how to run and install scripts on computercraft:
The scripts will tell you what you need but, in doubt, you can continue scrolling.
[Server script](https://pastebin.com/Xbn0fpKt)  
[Client script](https://pastebin.com/ZHgSJitZ)

### Server side
Place a computer on your minecraft world.  
Place next to it these peripherals:
- Modem (preferably, the Ender modem)
- Recipe registry
- Informative registry

This is an example:  
![server_setup](https://github.com/user-attachments/assets/66f615a3-f233-4e42-946e-c45a34fe52ad)

Now, right click the computer and paste this link for an express install: pastebin get https://pastebin.com/Xbn0fpKt startup.lua  
Then, restart the computer. You can press the red button on the left of the computer screen.  
The server side should be done and running correctly.

### Client side
Place a turle on your minecraft world (Not the animal, the computercraft machine!)

The turtle has two inventory spaces next to the 16 slots it already has.
Put in those two slots a crafting table and a modem (preferably, the Ender modem)  
Something like this:  
![client_setup](https://github.com/user-attachments/assets/0b2fac43-cddc-400f-b765-8bafbffaa993)  

Right click the turtle and paste this link for an express install: pastebin get https://pastebin.com/ZHgSJitZ startup.lua  
Then, restart the computer. You can press the red button on the left of the computer screen.  

## Client navigation

Here, you have to move using the arrow keys (No mouse suport, sorry, but the compatibility with metal tier 1 computers was more important)  

### First window: Select an item to craft

You will be prompted to select an item to craft from a list.  
Every item on the list can be crafted on a crafting table and, depending on how many mods you have installed, it can get insanely long!  
Fortunately, you can search for any item by writting it's name.  
The program even deals with items that are called the same but are from different mods. Just write this character: _:_

Here's the window:  
![client_window_1](https://github.com/user-attachments/assets/8f7a8f4c-8837-4041-93e3-22c74afab2eb)  

__Key legend__  
Any character key: (Write a name to search. The search will be executed as soon as you stop typing)  
Backspace key: (Delete a character from your name search bar)  
Arrow left/right keys: (Move the cursor from your name search bar)  

Arrow up/down keys: (Move item selection)  
PageUp/PageDown keys: (Previous/Next items page)  
Home/End keys: (Start/End of the items list)  
Enter key: (Confirm item selection and advance to next screen)  

### Second window: Select a recipe

If your item has more than one recipe, you will be prompted to select one.  
You will see the items represented in a crafting table pattern as colors and symbols.  
Every item name represented by those colors and symbols will be drawn bellow.  
You will also see what the recipe is making, and how much of it every time.  

Here's the window:  
![client_window_2](https://github.com/user-attachments/assets/a94655ae-a62b-4e71-a881-c1ff0f009c9f)


__Key legend__  
Arrow left/right keys: (Move the selection from the bar on the bottom)  
Enter key: (Confirm the button selected on the bottom bar)  

The Readme is still WIP.
