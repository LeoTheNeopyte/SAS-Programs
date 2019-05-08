*** prevents the macro from printing to the log ***;
options Mprint nomlogic;
%macro Clndataset( DATA_IN, DATA_OUT, NODROP= );

	********************************************************************
		Warnings if not minimum requirements met 
	*******************************************************************;
	%if "&DATA_IN" = "&DATA_OUT" %then %do;
		%put 'WARN''ING(AC): DATA INPUT AND OUTPUT CANNOT BE THE SAME';
		%put 'MACRO TERMINATING...';
		%goto EXIT;
	%end;
	
	%if &DATA_OUT = %then %do;
		%put 'WARN''ING(AC): OUTPUT NAME NOT SPECIFIED';
		%put 'MACRO TERMINATING...';
		%goto EXIT;
	%end;
	
	
	
	
%EXIT:
%mend Clndataset;


data test;
	var = 1;
	
	%clndataset(test, );

run;