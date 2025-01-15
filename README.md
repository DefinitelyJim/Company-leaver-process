1. Copy script to accessible location, e.g. for AD changes on prem.
2. Open powershell (AS ADMIN)
3. Type the following, be sure to replace ** with the relevant information: cd C:\Users\*user*\*desktop*.
Please be aware if you have installed it in another place you can find that directory the same way. For example:

cd C:\Users\DefinitelyJim\Documents\Scripts

4. Once you have guided powershell to the correct directory you then need to tell it to run the script in that location.
This is done by typing .\*scriptname*.ps1

It will not accept spaces, so when naming the script be sure to use snake_case naming convention or camelCase naming convention, .\script_name.ps1 or .\scriptName.ps1

5. Hit space and the script will then run, follow steps in the script from here.
