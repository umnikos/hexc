# hexc
A programming language that compiles down to hexcasting spells.

![image](https://github.com/user-attachments/assets/1bd0ce45-b454-4242-bcf4-18b31b8e568c)
![image](https://github.com/user-attachments/assets/0326d8ba-0d35-41b1-9ee0-688db7ddfb41)
![image](https://github.com/user-attachments/assets/43b39c51-d0a3-4aa6-86a4-d48ba09dfe3a)
![image](https://github.com/user-attachments/assets/3b5f025e-05f1-40be-b8c5-521cf6552bbd)
![image](https://github.com/user-attachments/assets/f0472e0e-a7d9-4dde-a8e3-70c1473e1be5)
![image](https://github.com/user-attachments/assets/a1e13bdb-ce89-403d-90ec-2da438ce85eb)
![image](https://github.com/user-attachments/assets/82ba6800-3ca6-4be7-b894-31fb279970ad)

Currently unfinished (and may never be finished) but it's also in a very usable state.

## Usage
This has been developed with the Hexxytest3 minecraft server in mind; To have it work as-is you will need to replicate that environment:
1. Install minecraft 1.20.1 fabric with the following mods:
    - CC:Tweaked
    - Plethora (for the Neural Interface)
    - Hexcasting
    - Hextweaks (for the Mindsplice Staff)
    - The rest of the hexcasting addons (listed in `scraper.nu`) (none of them are strictly required but the stdlib has been written with the expectation that those patterns exist)
    - (optional) Ducky peripherals (for the Focal Port)
2. Create a world with the seed `hexxytest` (otherwise you'll have to edit `symbol-overrides.nu` with your per-world patterns)
3. Get a Neural Interface and equip it with a Mindsplice Staff
4. Download `update.lua` and run it to fetch all of the code

After that `wand.lua` is a hexc repl which you can play around with.
You can also write a spell in a file and compile it with `hexc build`.
You can also import it as a lib to compile and/or run spells programatically.

To see the available list of pre-defined words, read:
- `symbols.json` - contains the standalone hexcasting patterns
- `stdlib.hx` - contains basic definitions that make writing spells easier
- `usrlib.hx` - contains entire pre-written spells
