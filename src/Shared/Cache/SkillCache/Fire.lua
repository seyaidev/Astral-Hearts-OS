return {
    Name = "Fire";
	BaseDamage 		= 12;
	Cost	= 12;
	UpgradeCost = 1;
	Max = 5;
	Status 			= {
		"burn";
	};
	Cooldown = 10;

	Image = 2131919919;
	Description = "A shot of fire created from Essence.";


	Speed 			= 65;
	Range 			= 1; --range = time in seconds, distance = Range * Speed
	LocalInfo = {};
	Callback 		= function(LocalServices)
	end
}