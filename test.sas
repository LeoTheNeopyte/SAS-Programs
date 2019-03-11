%let temp = "UN-UNK-2019";

data test;
	if &temp in: ("UN") then do;
		hello = "Hello world";
	end;
run;