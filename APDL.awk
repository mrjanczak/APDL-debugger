# MIT License
# Copyright (c) [2017] [Michal Janczak]
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ------------------------------------------------------------------------------------------------------------
# APDL Debugger tool to verify flow control commands and keywords in APDL code; ver. 2.2 (based on ANSYS v.17)
# ------------------------------------------------------------------------------------------------------------
# Tool generates file <tabulated.inp> with re-tabulated code according to its structure. 
# Lines with I/O data format [eg. (f4,f4)] are adjusted to left.
# To exclude part of code from debugging wrap it by !!!DEBUG_OFF!!! and !!!DEBUG_ON!!! tags.
# 													
# Usage in Textpad:
# -----------------
# Copy this file to local disk (FULL_PATH\APDL_2-2.awk)
# Configure Textpad menu Tools > Run... :
#   Command: C:\Apps\cygwin\bin\awk.exe
#   Parameter: -f FULL_PATH\APDL_2-2.awk $File
#   Initial folder: $FileDir
#   Check option 'Capture output'
# To verify apdl script click Tools > Run > OK and check output window.
#
# Change log
# ----------
# 2-2 - line 124 - fixed arguments with brackets
#
# To Do
# -----
# Messages *MSG,WARNING, N1, N2, MERID_DIST, MERID_TOL
#          Nodes %I & %I are in the same row (MERID_DIST %G < MERID_TOL %G). Reduce AX_CSYS_TOL.
#
# Nested brackets - MERID_CSYS = NINT( MERID_CSYS_X_( NX(N1), SIDEi ) )
#
# Validate arguments in *do, *dowile,*if - no operators allowed!!!

function print_msg(s) {
  print "------------------------------------------------------------------------";
  print s;
  print "------------------------------------------------------------------------";
}

function prev_level (arr) {
  lev = 0; len = 0;  
  for (i in arr) { len++; }
  for (i=0; i<=len; i++) { if(arr[i] > 0) {lev = i;}}
  return lev;
}

function print_arr (arr) {
  len = 1;  
  for (i in arr) { len++; }
  for (i=1; i<=len; i++) { printf "%s:%s ",i,arr[i]; }
  printf "\n";
}

function indent(ind) {
  str="";
  for(i=1; i<=ind; i++) {str=str "  ";}
  return str;
}

function ltrim(s) { gsub(/^[ \t]+/, "", s); return s }
function rtrim(s) { gsub(/[ \t]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }

BEGIN{
	FS=" "; LINE=0; LEV=0; apdl_ok=1; is_apdl=1; is_form=0; apdl_block=1; prev_line="";
	CR_LEV=0; DO_LEV=0; IF_LEV=0; 

	flowN=split("*create,*end,*do,*dowhile,*enddo,*if,*elseif,*else,*endif",flow,",");
	operN=split("eq,ne,lt,gt,le,ge,ablt,abgt",oper,",");
	base1N=split("and,or,xor",base1,",");
	base2N=split("stop,exit,cycle,then",base2,",");    
	declN=split("*dim,*set,*get,*vget,*vread,*tread",decl,",");
	formN=split("*msg,*vwrite,*mwrite,*vread,*tread",form,",");
	exclN=split("/com,c***,!,/sys,/syp,/title,/stitle,/tlabel,*abbr",excl,",");

	abcN=26; abc="ABCDEFGHIJKLMNOPRSTUVWXYZ";	
	keys[1]="A,ACTIVE,ACUS,ADDMAS,ADJ,AINDEX,AMAS,AMPL,AMPS,ANG,ANGLE,ANLD,ANLN,ANLX,ANTY,APROJ,AREA,ARRAY,ASEL,ASTP,ATTR,AXIS"
	keys[2]="B,BASIC,BBML,BFE,BMAX,BMIN,BMOM,BSAX,BSCF,BSM1,BSM2,BSMD,BSS1,BSS2,BSTE,BSTQ"
	keys[3]="CAMP,CBMD,CBMX,CBTE,CCDL,CDM,CDSY,CE,CENT,CENTER,CEXT,CG,CGITER,CGY,CGZ,CHAR,CHRG,CINT,CMD,CMPB,CNVG,COEF,COMP,CONC,CONST,CONTOUR,CORR,COUNT,CP,CPS,CPU,CREQ,CRPRAT,CSCV,CSEC,CSGX,CSGY,CSGZ,CSYS,CTIP,CUCV,CURR,CURT,CVAR,CYCCALC"
	keys[4]="D,DAMP,DATA,DBASE,DDAM,DEF,DF,DFRQ,DG,DGEN,DICV,DIM,DISPLAY,DIST,DIV,DOF,DSCALE,DSHOCK,DSPRM,DSTF,DSYS,DTYPE,DVOL"
	keys[5]="EDCC,EDGE,EF,EFOR,ELEM,EMAX,EMF,EPCR,EPDI,EPEL,EPEQ,EPPL,EPSW,EPTH,EPTO,EPTT,EQIT,EQV,ERASE,ESEL,ESYM,ESYS,ETAB,ETYP,EXIS,EXTREM"
	keys[6]="F,FAIL,FFCV,FICT,FIELD,FIRST,FKCN,FLOW,FLUX,FMAG,FMC,FOCUS,FOCV,FREQ,FSOU,FSUM,FUNC,FX,FY,FZ"
	keys[7]="G1,G2,G3,GCN,GENB,GENS,GKD,GKDI,GKS,GKTH,GLINE,GRAPH,GSRESULT,GT"
	keys[8]="H,HCOE,HEAT,HFCV,HFIB,HGEN,HMAT,HORC,HPRES,HS"
	keys[9]="IANG,IIN1,IIN2,IIN3,IMAG,IMAX,IMC,IMIN,IMME,INSIDE,INT,INTSRF,IOR,IPR,IPRIN,ISET,ITEM,IVAL,IXV,IYV,IYY,IYZ,IZV,IZZ"
	keys[10]="JHEAT,JINT,JOBNAM,JS,JVAL"
	keys[11]="K,K1,K2,K3,KCALC,KENE,KP,KSEL,KURT,KVAL"
	keys[12]="L3FB,L3MT,L4FB,L4MT,LAB,LAST,LAYD,LDATE,LDEN,LENG,LFIBER,LINE,LM,LOC,LOOP,LPROJ,LSEL,LTIME"
	keys[13]="M,MAC,MAG,MAT,MATM,MAX,MAXD,MAXF,MAXP,MAXPATH,MAXY,MAXZ,MC,MCOEF,MEAN,MENU,METH,MFCV,MFTX,MFTY,MFTZ,MIN,MIND,MINY,MINZ,MMMC,MMOR,MNLOC,MOCV,MODE,MODM,MPLAB,MSCF,MTOT,MX,MXDVL,MXLOC,MY,MZ"
	keys[14]="NAME,NARGS,NBMO,NBST,NCMIT,NCMLS,NCMSS,NCOL,NCOMP,NDIST,NETHF,NL,NLAY,NLENG,NMISC,NODE,NORMAL,NPROC,NREIN,NRELM,NRSS,NS1,NS2,NSCOMP,NSEL,NSET,NSETS,NSIM,NSOL,NSP,NTEM,NTEMP,NTERM,NTRP,NTRV,NUM,NUMBER,NUMCPU,NUMPATH,NVAL,NXTH,NXTL"
	keys[15]="OCEAN,OCZONE,OFFSET,OFFY,OFFZ,ORBT,OUTSIDE"
	keys[16]="PAR1,PAR2,PAR3,PAR4,PARM,PART,PATH,PFACT,PFIB,PG,PHASE,PIPE,PLATFORM,PLNSOL,PLOPTS,PLWK,PMAT,POINT,POS,PRCV,PRERR,PRES,PRKEY,PROP,PRTM,PS,PSINC,PSMAX,PSV,PWL"
	keys[18]="RAD,RANGE,RATE,RATIO,RCON,REAL,REIN,RELM,RESEIG,RESFRQ,REV,RF,RLAB,RMS,RNAM,ROCV,ROT,ROTX,ROTY,ROTZ,ROUT,RSEQ,RSET,RSST,RSTMAC,RSUR,RSYS"
	keys[19]="S,SAMP,SBST,SCTN,SCYY,SCYZ,SCZZ,SDSG,SECM,SECMAX,SECNODE,SECNUM,SECP,SECR,SECT,SECTION,SEG,SENE,SENSM,SEPC,SERR,SERSM,SET,SFLEX,SHCY,SHCZ,SHEL,SHELL,SHPAR,SHRINK,SKEW,SMAX,SMCV,SMISC,SNAME,SOLU,SORT,SPL,SPLA,SRAT,SSBT,SSCALE,SSMT,SSPA,SSPB,SSPD,SSPE,SSPM,SSUM,STAB,STAT,STDV,STTMAX,SUBTYPE"
	keys[20]="TABL,TAUW,TBFT,TBLAB,TBULK,TDSG,TECV,TEMP,TENE,TENSM,TEPC,TERM,TERR,TERSM,TF,TG,THXY,THYZ,THZX,TIME,TITLE,TLAST,TMAX,TMIN,TORS,TS,TS11,TS12,TS22,TSTRESS,TVAL,TWSI,TWSR,TXY,TXZ,TYPE,TYPM"
	keys[21]="U,UKEY,UNITS,USR1,USR2,USR3,USR4,USR5,USR6,USR7,USR8,USR9,UT11,UT12,UT22,UX,UY,UZ"
	keys[22]="V,VAR,VARI,VCONE,VCRI,VDIS,VECV,VFAVG,VIEW,VLAST,VLTG,VMAX,VMCV,VMIN,VNAM,VOCV,VOLT,VOLU,VSCALE,VSEL,VSTA"
	keys[23]="WALL,WARP,WELD,WFRONT,WHRL"
	keys[24]="X,XFEM,XMAX,XMIN,XY"
	keys[25]="Y,YMAX,YMIN,YZ"
	keys[26]="Z"

	warnings="";
	warningsN=0;
    
	print "! ------------------------------------------------------------------------">  "tabulated.inp";
	printf "! Code generated by APDL.awk tool on " strftime("%m.%d.%Y %H:%M:%S") "\n" >> "tabulated.inp"; 
	print "! ------------------------------------------------------------------------">> "tabulated.inp";

}

{
	LINE++;

	if($0~/\!\!\!DEBUG_OFF\!\!\!/) { apdl_block=0; is_apdl=0;}	
	if($0~/\!\!\!DEBUG_ON\!\!\!/) {  apdl_block=1; is_apdl=1;}
	
	line_org=trim($0);
	line_prep0=line_org;
	
	# Replace strings in quotation by "..."
	gsub(/'[^']*'/,"...",line_prep0); #'
	gsub(/"[^"]*"/,"...",line_prep0); #"

	# Split lines by "!" to exclude comments
	commN=split(line_prep0,line_prep,"!");
	is_comm = 0; if(commN>1) {is_comm=1}
	
	# Split actual lines by "$" into sublines
	sublinesN=split(line_prep[1],sublines,"$");
	for(sl=1;sl<=sublinesN;sl++) {

		subline=trim(sublines[sl]);
		subline_org = subline;
		
		show_line=0;
			
		if(apdl_block) {
				
			# Append words from not empty brackets to list of words in line
			i=0;
			while( match(subline,/(\([^\(\)]+\))/)>0 ) { 
				inBracket=substr(subline,RSTART+1,RLENGTH-2); 
				subline=substr(subline,RSTART+RLENGTH); 
				wordsBN=split(inBracket,wordsB,","); 
				for(j=1;j<=wordsBN;j++) {i++; allWordsB[i]=wordsB[j] } }
			allWordsBN=i;

			# Remove brackets
			subline = subline_org;		
			gsub(/(\([^\(\)]+\))/,"()",subline);	

			# Split subline by ","
			wordsCN=split(subline,wordsC,","); 

			# Append words from brackets
			for(i=1;i<=allWordsBN;i++) {
				wordsC[wordsCN+i]=allWordsB[i]; }
			wordsCN=wordsCN+allWordsBN;

			# Remove brackets from FORTRAN format 
			if(wordsC[1]~/$\(/) { 
				gsub(/\(/,"",wordsC[1]); 
				gsub(/\)/,"",wordsC[wordsCN]) }

			is_excl=0;
			for(i=1;i<=exclN;i++) {		
				if(index(wordsC[1],excl[i])) {is_excl=1; break; }}

			# Split line by "=", then split words after to wordsC
			wordsEN=0;
			if(!is_excl) {
				wordsEN=split(subline,wordsE,"=");
				if(wordsEN == 2) {			
					wordsCN=split(wordsE[2],wordsC,","); } }

			for(i=1;i<=wordsCN;i++) {
				wordsC[i]=tolower(trim(wordsC[i])); }	
			
			# Validate only APDL lines (comments, system commands, output formats and commands with text field)
			is_apdl=1; 
			if(is_excl) { is_apdl=0; }
						
			# Look for lines just below FORTRAN or C format
			if(is_form && prev_line!~/\%\/\&/) {is_form=0;}

			# Look for lines with FORTRAN or C format following commands like '*msg' or '*vwrite'
			for(i=1;i<=formN;i++) {		
				if(index(prev_line,form[i])) {is_form=1; break; }}

			# Validate only APDL lines (not comments, system commands and output formats)
			if(is_form) { is_apdl=0; }	
		}
		
		if(is_apdl) {
		
			# --------------------------
			# Operator validation		
			# --------------------------				
			for(i=1;i<=wordsCN;i++) {	
				if(wordsC[i]~/[a-z0-9_]+[^\+\-\*\/\<\>]*[ \t][^\+\-\*\/\<\>]*[a-z0-9_]+/) {
					print_msg("*** Error *** in line #" LINE " - missing operator."); apdl_ok=0; show_line=1;} 
				if(wordsC[i]~/[ \t]\*/) {
					print_msg("*** Error *** in line #" LINE " - space before operator *."); apdl_ok=0; show_line=1;} } 											

			if(wordsEN > 2) {
				print_msg("*** Error *** in line #" LINE " - wrong parameter setting."); apdl_ok=0; show_line=1;} 
						
			# --------------------------
			# Parameter name validation		
			# --------------------------
			is_param=0;

			if(wordsEN == 2) {
				PARAM = trim(toupper(wordsE[1]));
				is_param=1 }

			# Look for commands declaring params
			for(i=1;i<=declN;i++) {			
				if(index(wordsC[1],decl[i])) {
					PARAM=toupper(wordsC[2]);
					is_param=1;
					break; } }
			
			gsub(/\(\)$/,"",PARAM);
			
			if(is_param) {			    
				# Validate name 
				if(PARAM~/^[0-9]/ || PARAM~/[^a-zA-Z0-9_]/) {
					print_msg("*** Error *** in line #" LINE " - wrong name of param (" PARAM ")."); apdl_ok=0; show_line=1;}
				
				if(length(PARAM) > 32) {
					print_msg("*** Error *** in line #" LINE " - param name too long (" PARAM ")."); apdl_ok=0; show_line=1;}
					
				# Compare parameter name with keywords 
				for(j=1;j<=abcN;j++){			
					if(substr(PARAM,1,1)==substr(abc,j,1)) {	
						keysN=split(keys[j],keywords,",")
						for(i=1; i<=keysN; i++) {	
							if(PARAM==keywords[i]) {
								warnings=warnings "- "PARAM " (line " LINE ") - param same as KEYWORD \n ";
								warningsN++;
								break;
							}
						}
						break;
					}
				}
			}  

			# -----------------------
			# Flow control validation		
			# ----------------------- 
			is_flow=0; for(i=1;i<=flowN;i++) {
				if(wordsC[1]==flow[i]) {is_flow=1; show_line=1; break;}} 

			if(wordsC[1]=="*create") {
				LEV++; CR_LEV=LEV; CR_[LEV]=LINE; CR_[0]=LINE;
				if(wordsCN-allWordsBN<3) {
					print_msg("*** Error *** in line #" LINE " - wrong number of arguments (" wordsCN ") in command *create."); apdl_ok=0;} }

			if(wordsC[1]=="*do") {
				LEV++; DO_LEV=LEV; DO_[LEV]=LINE; DO_[0]=LINE;
				if(wordsCN-allWordsBN<4) {
					print_msg("*** Error *** in line #" LINE " - wrong number of arguments (" wordsCN ") in command *do."); apdl_ok=0;} }

			if(wordsC[1]=="*dowhile") {
				LEV++; DO_LEV=LEV; DO_[LEV]=LINE; DO_[0]=LINE;
				if(wordsCN-allWordsBN<2) {
					print_msg("*** Error *** in line #" LINE " - wrong number of arguments (" wordsCN ") in command *dowile."); apdl_ok=0;} }

			if((wordsC[1]=="*if") || (wordsC[1]=="*elseif")) {
				for(i=1;i<=wordsCN;i++) {wordsC[i]=tolower(wordsC[i]);}		

				if((wordsC[1]=="*if") && ((wordsC[5]=="then") || (wordsC[9]=="then")) ) {LEV++; IF_LEV=LEV; IF_[LEV]=LINE; }

				if(wordsC[1]=="*if") {IF_[0]=LINE;}

				if((wordsC[1]=="*elseif") && ((IF_LEV!=LEV) || !(IF_LEV>0)) ) {
						print_msg("*** Error *** in line #" LINE " - command *elseif on wrong level (see line #" IF_[IF_LEV] ")."); apdl_ok=0;}

				if((wordsCN-allWordsBN!=5) && (wordsCN-allWordsBN!=9)) {
					print_msg("*** Error *** in line #" LINE " - wrong number of arguments (" wordsCN ") in command *if."); apdl_ok=0;}

				oper1_ok=1; base1_ok=1; oper2_ok=1; base2_ok=1;
				if(wordsCN-allWordsBN==5) {
					oper1_ok=0;  for(i=1;i<=operN;i++) {if(wordsC[3]==oper[i]) {oper1_ok=1; break;} } }
				if(wordsCN-allWordsBN==9) {
					oper1_ok=0; for(i=1;i<=operN;i++) {if(wordsC[3]==oper[i]) {oper1_ok=1;break;} }
					base1_ok=0; for(i=1;i<=base1N;i++) {if(wordsC[5]==base1[i]) {base1_ok=1;break;} }
					oper2_ok=0; for(i=1;i<=operN;i++) {if(wordsC[7]==oper[i]) {oper2_ok=1;break;} }
				}
				if(!oper1_ok) {
					print_msg("*** Error *** in line #" LINE " - wrong argument (" wordsC[3] ") in command *if."); apdl_ok=0;}
				if(!base1_ok) {
					print_msg("*** Error *** in line #" LINE " - wrong argument (" wordsC[5] ") in command *if."); apdl_ok=0;}
				if(!oper2_ok) {
					print_msg("*** Error *** in line #" LINE " - wrong argument (" wordsC[7] ") in command *if."); apdl_ok=0;}

				oper1_ok=1; base1_ok=1; oper2_ok=1; base2_ok=1;
				if(substr(wordsC[5],1,1)!=":") {
					if(wordsCN-allWordsBN==5) {
						base1_ok=0;  for(i=1;i<=base2N;i++) {if(wordsC[5]==base2[i]) {base1_ok=1;break;} } }
					if(wordsCN-allWordsBN==9) {
						base2_ok=0; for(i=1;i<=base2N;i++) {if(wordsC[9]==base2[i]) {base2_ok=1;break;} } }
					if(!base1_ok) {
						print_msg("*** Error *** in line #" LINE " - wrong argument (" wordsC[5] ") in command *if."); apdl_ok=0;}
					if(!base2_ok) {
						print_msg("*** Error *** in line #" LINE " - wrong argument (" wordsC[9] ") in command *if."); apdl_ok=0;}      
				}          
			}
			
			is_flow ? IND=LEV-1 : IND=LEV; 
			if(wordsC[1]=="*if" && wordsC[5]!="then" && wordsC[9]!="then") {IND=LEV}
			IND<0 ?   IND=0     : IND=IND;

			if(wordsC[1]=="*end") {
				if((CR_LEV==LEV) && (CR_LEV>0)) {CR_[LEV]=0; LEV--; CR_LEV=prev_level(CR_); }
				else{ print_msg("*** Error *** in line #" LINE " - command *end on wrong level (see line #" CR_[CR_LEV] ")."); apdl_ok=0;}}

			if(wordsC[1]=="*enddo") { 
				if((DO_LEV==LEV) && (DO_LEV>0)) { DO_[LEV]=0; LEV--; DO_LEV = prev_level(DO_); }
				else{ print_msg("*** Error *** in line #" LINE " - command *enddo on wrong level (see line #" DO_[DO_LEV] ")."); apdl_ok=0;} }

			if(wordsC[1]=="*endif")   {
				if((IF_LEV==LEV) && (IF_LEV>0)) { IF_[LEV]=0; LEV--; IF_LEV = prev_level(IF_); }
				else{print_msg("*** Error *** in line #" LINE " - command *endif on wrong level (see line #" IF_[IF_LEV] ")."); apdl_ok=0;}	}
				
			if(show_line) {printf "#%-4i[%i|%i|%i:%i] %s%s\n",LINE,CR_LEV,DO_LEV,IF_LEV,LEV,indent(IND),subline; } 

		} # End of validation of APDL line
		
		prev_line = line_org
		
	} # End Do for sublines 
	
	if(is_form) {print line_org >> "tabulated.inp"; }		
	else {printf "%s%s\n",indent(IND),line_org >> "tabulated.inp"; } 
}

END{
  	if(apdl_ok) {print_msg("APDL code seems to be correct!");}
  	else {print_msg("APDL code has errors!");}
	if(warningsN>0) { print_msg("*** Warnings *** \n " warnings);}  
}
