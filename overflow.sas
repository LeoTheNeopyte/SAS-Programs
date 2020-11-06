/******************************************************************************************************************
Program Name    : Overflow.sas  
Purpose         : Separates strings into 200 length without cutting words per CDISC guidance
Programmer      : LGomez
Date            : 02NOV2020
Comments        : 
     Program expands variables with length of more than 200 into muliple variables of 200. 
     Follows SDTMIG standad for variable namening (section 4.1.2.9, pg 38, version 3.2). 
     
     Parameters:
      dset - Input dataset.
     Info and rules:
      - dset: Default to WORK directory if no library specified. 
      - reanames original variable with a sufix of X.
           -The first variable will receive the original name, while the rest of the variables
            will have a suffix of 1-N.
            EX:  COVALX, COVAL, COVAL1, COVAL2, ... ,COVALn
      - Generates warning if input dataset does not exist or if no variables with more than 200 found.
     Output:
      - Same as input dataset with a underscore as suffix.

     WILL BREAK IF:
     - Any finction is added as input (i.e rename, where, keep, etc);
        EX: %overflow(db.ae(rename = (Subject_id = SUBJID)));

    Future Plans:
     traverse through directory
******************************************************************************************************************/

%macro overflow(dset);
*************************************************************************************
    Prevents input from breaking macro and gives warning if dataset does not exist
    Formats data as follows:
    Input = DB.ae -> db.ae
*************************************************************************************;
%if %index("&dset", .) > 0 %then %do;
    %let lib  = %lowcase(%scan(&dset, 1));
    %let data = %lowcase(%scan(&dset, 2));
%end;
%else %do;
    %let lib  = work;
    %let data = %lowcase(%scan(&dset, 1));
%end;
%if %sysfunc(exist(&lib..&data.)) = 0 %then %put WARNING (AC): DATASET &dset DOES NOT EXIST;
%else %do;
data tempmacroset;
    set &dset;
run; 

/*data tempmacroset;*/
/*    set db.acm_labs;*/
/*run; */
*************************************************************************************
    Resizes variable lengnths of > 200 but Content <200 into a dataset
    call "fixlen"
        ex:   COVAL = "Hello" (length = 600)  ->  COVAL = "Hello" (length = 5)
*************************************************************************************;
option spool;
proc sql;
    create table tempmacrovar as
    select name
    from dictionary.columns
    where upcase(libname) ="WORK" & upcase(memname) ="TEMPMACROSET" & LENGTH > 200;
quit;

*** check if tempmacrovar is empty dataset ***;
data _null_;
    call symputx('obscnt',0);
    set tempmacrovar;
    call symputx('obscnt',_n_);
    stop;
run;

%if &obscnt. ne 0 %then %do;
    data _null_;
        call execute('proc sql noprint; select ');
            do until(done);
              set tempmacrovar end=done;
              call execute('max(length(' !! strip(name) !! '))');
              if not done then call execute(',');
            end;
        call execute(' into ');
            do until (done1);
              set tempmacrovar end=done1;
              call execute(':' !! strip(name));
              if not done1 then call execute(',');
            end;
        call execute("from tempmacroset; quit;");
        stop;
    run;

    data _null_;
        call execute("data fixlen; set tempmacroset (rename=(");
        do until (done);
          set tempmacrovar end=done;
          call execute(strip(name) !! '=_' !! strip(name) !! ' ');
        end;
        call execute(')); length ');
        do until (done2);
          set tempmacrovar end=done2;
          call execute(strip(name) !! ' $&' !! strip(name) !! '. ');
        end;
        call execute(';');
        do until (done3);
          set tempmacrovar end=done3;
          call execute(strip(name) !! '=_' !! strip(name) !! ';');
        end;
        call execute('drop ');
        do until (done4);
          set tempmacrovar end=done4;
          call execute('_' !! strip(name) !! ' ');
        end;
        call execute('; run;');
        stop;
    run;
%end;
option nospool;
*************************************************************************************
    Varname1-n: list the variable names
    len1-n    : Number of variables needed to expand (i.e length=600 len=3)
    totlen1-n : Total length of variable
    vlistn    : Number of variables with > 200
*************************************************************************************;
proc sql noprint;
    select NAME, floor(length/200), length
    into :varname0 - :varname99,
         :len0 - :len99,
         :totlen0 - :totlen99
    from dictionary.columns
    where upcase(libname) ="WORK" & upcase(memname) ="FIXLEN" & LENGTH > 200;
    %let vlistn = %eval(&sqlobs - 1);
    %let obsn = &sqlobs;
quit;
/*%put &vlistn;*/
/*%put &varname0;*/
/*%put &varname1;*/
/*%put &totlen0;*/
/*%put &totlen1;*/
/*%put &len0;/
/*%put &len1;*/

*************************************************************************************
    Expands variable into multiptle 200 char variables, followed
    by a Nth Suffic.
        EX: if variable "COVAL" has length of 580 then data will be
            presented as follows:
  |-----------------------------------------------------------------------------|
  |  COVAL1 (From 1 - 200) | COVAL2 (From 200 - 400) |  COVAL3 (From 400 - 600) |
  |-----------------------------------------------------------------------------|
*************************************************************************************;
%macro dothis;
data _&data (drop = m_x m_left m_leftN m_right m_rightN m_head m_leng);
  set tempmacroset;

  %do i = 0 %to &vlistn.;
    rename &&varname&i.. = &&varname&i..X  &&varname&i..0 = &&varname&i..;
    m_leng = ifn(missing(&&varname&i..), ., length(&&varname&i..));
    m_x = 1;
    m_left = 1;
    m_right = 200;
    m_head = 200;

    array newvars&i. $200 &&varname&i..0 - &&varname&i.&&len&i.;

    do over newvars&i.;
        *** Determine left and right nodes ***;
        if m_head >= m_leng then do; *** if Node is at the end of string ***;
            if m_left < m_leng then m_leftN = findc(substr(strip(&&varname&i.), m_left), ' ', "bi");*** Find first space from m_left ***;
            m_rightN = m_leng;
        end;
        else do;
            m_leftN = findc(substr(&&varname&i., m_left, 201), ' ', "bi");
            m_rightN = m_head + findc(substr(&&varname&i., m_head+1), ' ', "i");
        end;
        if m_x = 1 & ~missing(&&varname&i.) then do;
            if m_leftN = 0 then do; *** in case the first word is bigger than 200 ***;
                newvars&i.[m_x] = substr(&&varname&i., m_left, 200);
                m_left = m_leftN + 201;
            end;
            else if m_leng <= 200 then do;  *** in case the length variable is less than 200 ***;
                newvars0[m_x] = substr(&&varname&i., m_left);
                m_left = 200;
            end;
            else do;
                newvars&i.[m_x] = substr(&&varname&i., m_left, m_leftN);
                m_left = m_left + m_leftN;
            end;
            m_right = m_left + 200;
            m_head = m_right;
        end;
        else if m_rightN = m_leng and ~missing(&&varname&i.) then do;
            newvars&i.[m_x] = substr(&&varname&i., m_left);
            m_rightN = m_rightN + 1;
            m_leftN = m_head;
            m_left = m_head;
        end;
        else if m_leftN < m_head and ~missing(&&varname&i.) then do;
            if m_leftN = 0 then newvars&i.[m_x] = substr(&&varname&i., m_left, 200);
            else newvars&i.[m_x] = substr(&&varname&i., m_left, m_leftN);
            m_left = m_left + m_leftN;
            m_right = m_left + 200;
            m_head = m_right;
        end;
        m_x + 1;
    end;
  %end;
run;
%mend dothis;
*** check for empty/no variables over 200 ***;
%if &obsn. eq 0 %then %do;
    %put /------------------------------------------------------------------------------------\;
    %put ;
    %put ;
    %put  WARNING: DATASET &data HAS NO VARIABLES WITH OVER 200 CHARACTERS;
    %put ;
    %put ;
    %put \------------------------------------------------------------------------------------/;
%end;
%else %do;
    %dothis;
%end;

/**** removes temporary datasets ***;*/
/*proc datasets nolist lib=work;*/
/*  delete tempmacroset tempmacrovar;*/
/*quit;*/

%end;
%mend overflow;

%overflow(db.acm_labs);
