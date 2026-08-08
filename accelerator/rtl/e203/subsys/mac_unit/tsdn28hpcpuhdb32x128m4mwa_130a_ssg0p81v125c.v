//*#*********************************************************************************************************************/
//*# Software       : TSMC MEMORY COMPILER tsn28hpcpuhddpsram_2012.02.00.d.130a						*/
//*# Technology     : TSMC 28nm CMOS LOGIC High Performance Compact Mobile 1P10M HKMG CU_ELK 0.9V				*/
//*# Memory Type    : TSMC 28nm High Performance Compact Mobile Ultra High Density Dual Port SRAM with d127 bit cell SVT Periphery */
//*# Library Name   : tsdn28hpcpuhdb32x128m4mwa (user specify : TSDN28HPCPUHDB32X128M4MWA)				*/
//*# Library Version: 130a												*/
//*# Generated Time : 2025/09/14, 14:20:31										*/
//*#*********************************************************************************************************************/
//*#															*/
//*# STATEMENT OF USE													*/
//*#															*/
//*# This information contains confidential and proprietary information of TSMC.					*/
//*# No part of this information may be reproduced, transmitted, transcribed,						*/
//*# stored in a retrieval system, or translated into any human or computer						*/
//*# language, in any form or by any means, electronic, mechanical, magnetic,						*/
//*# optical, chemical, manual, or otherwise, without the prior written permission					*/
//*# of TSMC. This information was prepared for informational purpose and is for					*/
//*# use by TSMC's customers only. TSMC reserves the right to make changes in the					*/
//*# information at any time and without notice.									*/
//*#															*/
//*#*********************************************************************************************************************/
///*******************************************************************************/
//*      Usage Limitation: PLEASE READ CAREFULLY FOR CORRECT USAGE               */
//* The model doesn't support the control enable, data, address signals          */
//* transition at positive clock edge.                                           */
//* Please have some timing delays between control/data/address and clock signals*/
//* to ensure the correct behavior.                                              */
//*                                                                              */
//* Please be careful when using non 2^n  memory.                                */
//* In a non-fully decoded array, a write cycle to a nonexistent address location*/
//* does not change the memory array contents and output remains the same.       */
//* In a non-fully decoded array, a read cycle to a nonexistent address location */
//* does not change the memory array contents but output becomes unknown.        */
//*                                                                              */
//* In the verilog model, the behavior of unknown clock will corrupt the         */
//* memory data and make output unknown regardless of CEB signal.  But in the    */
//* silicon, the unknown clock at CEB high, the memory and output data will be   */
//* held. The verilog model behavior is more conservative in this condition.     */
//*                                                                              */
//* The model doesn't identify physical column and row address                   */
//*                                                                              */
//* The verilog model provides TSMC_CM_UNIT_DELAY mode for the fast function     */
//* simulation.                                                                  */
//* All timing values in the specification are not checked in the                */
//* TSMC_CM_UNIT_DELAY mode simulation.                                          */
//*                                                                              */
//*                                                                              */
//*                                                                              */
//* Please use the verilog simulator version with $recrem timing check support.  */
//* Some earlier simulator versions might support $recovery only, not $recrem.   */
//*                                                                              */
//* Template Version : S_01_61101                                       */
//****************************************************************************** */
//*      Macro Usage       : (+define[MACRO] for Verilog compiliers)             */
//* +TSMC_CM_UNIT_DELAY : Enable fast function simulation.                       */
//* +no_warning : Disable all runtime warnings message from this model.          */
//* +TSMC_INITIALIZE_MEM : Initialize the memory data in verilog format.         */
//* +TSMC_INITIALIZE_FAULT : Initialize the memory fault data in verilog format. */
//* +TSMC_NO_TESTPINS_WARNING : Disable the wrong test pins connection error     */
//*                             message if necessary.                            */
//****************************************************************************** */

`resetall
`celldefine

// `timescale 1ns/1ps
`delay_mode_path
`suppress_faults
`enable_portfaults

module TSDN28HPCPUHDB32X128M4MWA
    (
           RTSEL,
           WTSEL,
           PTSEL,
    AA,
    DA,
    BWEBA,
    WEBA,CEBA,CLK,
    AB,
    DB,
    BWEBB,
    WEBB,CEBB,
    AWT,
    QA,
    QB
  );

// Parameter declarations
parameter  N = 128;
parameter  W = 32;
parameter  M = 5;
parameter  RA = 3;

    wire SLP=1'b0;
    wire DSLP=1'b0;
    wire SD=1'b0;
    input [1:0] RTSEL;
    input [1:0] WTSEL;
    input [1:0] PTSEL;

// Input-Output declarations

    input [M-1:0] AA;
    input [N-1:0] DA;
    input [N-1:0] BWEBA;

    input WEBA;
    input CEBA;
    input CLK;
    input [M-1:0] AB;
    input [N-1:0] DB;
    input [N-1:0] BWEBB;
    input WEBB;
    input CEBB;
    input AWT;
    output [N-1:0] QA;
    output [N-1:0] QB;

`ifdef no_warning
parameter MES_ALL = "OFF";
`else
parameter MES_ALL = "ON";
`endif

`ifdef TSMC_CM_UNIT_DELAY
parameter  SRAM_DELAY = 0.010;
`endif
`ifdef TSMC_INITIALIZE_MEM
parameter INITIAL_MEM_DELAY = 0.01;
`else
  `ifdef TSMC_INITIALIZE_MEM_USING_DEFAULT_TASKS
parameter INITIAL_MEM_DELAY = 0.01;
  `endif
`endif
`ifdef TSMC_INITIALIZE_FAULT
parameter INITIAL_FAULT_DELAY = 0.01;
`endif

`ifdef TSMC_INITIALIZE_MEM
parameter cdeFileInit  = "TSDN28HPCPUHDB32X128M4MWA_initial.cde";
`endif
`ifdef TSMC_INITIALIZE_FAULT
parameter cdeFileFault = "TSDN28HPCPUHDB32X128M4MWA_fault.cde";
`endif

// Registers
reg invalid_aslp;
reg invalid_bslp;
reg invalid_adslp;
reg invalid_bdslp;
reg invalid_sdwk_dslp;

reg [N-1:0] DAL;
reg [N-1:0] DBL;
reg [N-1:0] bDBL;
 
reg [N-1:0] BWEBAL;
reg [N-1:0] BWEBBL;
reg [N-1:0] bBWEBBL;
 
reg [M-1:0] AAL;
reg [M-1:0] ABL;
 
reg WEBAL,CEBAL;
reg WEBBL,CEBBL;
 
wire [N-1:0] QAL;
wire [N-1:0] QBL;

reg valid_testpin;


reg valid_ck,valid_cka,valid_ckb;
reg valid_cea, valid_ceb;
reg valid_wea, valid_web;
reg valid_aa;
reg valid_ab;
reg valid_contentiona,valid_contentionb,valid_contentionc;
reg valid_da127, valid_da126, valid_da125, valid_da124, valid_da123, valid_da122, valid_da121, valid_da120, valid_da119, valid_da118, valid_da117, valid_da116, valid_da115, valid_da114, valid_da113, valid_da112, valid_da111, valid_da110, valid_da109, valid_da108, valid_da107, valid_da106, valid_da105, valid_da104, valid_da103, valid_da102, valid_da101, valid_da100, valid_da99, valid_da98, valid_da97, valid_da96, valid_da95, valid_da94, valid_da93, valid_da92, valid_da91, valid_da90, valid_da89, valid_da88, valid_da87, valid_da86, valid_da85, valid_da84, valid_da83, valid_da82, valid_da81, valid_da80, valid_da79, valid_da78, valid_da77, valid_da76, valid_da75, valid_da74, valid_da73, valid_da72, valid_da71, valid_da70, valid_da69, valid_da68, valid_da67, valid_da66, valid_da65, valid_da64, valid_da63, valid_da62, valid_da61, valid_da60, valid_da59, valid_da58, valid_da57, valid_da56, valid_da55, valid_da54, valid_da53, valid_da52, valid_da51, valid_da50, valid_da49, valid_da48, valid_da47, valid_da46, valid_da45, valid_da44, valid_da43, valid_da42, valid_da41, valid_da40, valid_da39, valid_da38, valid_da37, valid_da36, valid_da35, valid_da34, valid_da33, valid_da32, valid_da31, valid_da30, valid_da29, valid_da28, valid_da27, valid_da26, valid_da25, valid_da24, valid_da23, valid_da22, valid_da21, valid_da20, valid_da19, valid_da18, valid_da17, valid_da16, valid_da15, valid_da14, valid_da13, valid_da12, valid_da11, valid_da10, valid_da9, valid_da8, valid_da7, valid_da6, valid_da5, valid_da4, valid_da3, valid_da2, valid_da1, valid_da0;
reg valid_db127, valid_db126, valid_db125, valid_db124, valid_db123, valid_db122, valid_db121, valid_db120, valid_db119, valid_db118, valid_db117, valid_db116, valid_db115, valid_db114, valid_db113, valid_db112, valid_db111, valid_db110, valid_db109, valid_db108, valid_db107, valid_db106, valid_db105, valid_db104, valid_db103, valid_db102, valid_db101, valid_db100, valid_db99, valid_db98, valid_db97, valid_db96, valid_db95, valid_db94, valid_db93, valid_db92, valid_db91, valid_db90, valid_db89, valid_db88, valid_db87, valid_db86, valid_db85, valid_db84, valid_db83, valid_db82, valid_db81, valid_db80, valid_db79, valid_db78, valid_db77, valid_db76, valid_db75, valid_db74, valid_db73, valid_db72, valid_db71, valid_db70, valid_db69, valid_db68, valid_db67, valid_db66, valid_db65, valid_db64, valid_db63, valid_db62, valid_db61, valid_db60, valid_db59, valid_db58, valid_db57, valid_db56, valid_db55, valid_db54, valid_db53, valid_db52, valid_db51, valid_db50, valid_db49, valid_db48, valid_db47, valid_db46, valid_db45, valid_db44, valid_db43, valid_db42, valid_db41, valid_db40, valid_db39, valid_db38, valid_db37, valid_db36, valid_db35, valid_db34, valid_db33, valid_db32, valid_db31, valid_db30, valid_db29, valid_db28, valid_db27, valid_db26, valid_db25, valid_db24, valid_db23, valid_db22, valid_db21, valid_db20, valid_db19, valid_db18, valid_db17, valid_db16, valid_db15, valid_db14, valid_db13, valid_db12, valid_db11, valid_db10, valid_db9, valid_db8, valid_db7, valid_db6, valid_db5, valid_db4, valid_db3, valid_db2, valid_db1, valid_db0;
reg valid_bwa127, valid_bwa126, valid_bwa125, valid_bwa124, valid_bwa123, valid_bwa122, valid_bwa121, valid_bwa120, valid_bwa119, valid_bwa118, valid_bwa117, valid_bwa116, valid_bwa115, valid_bwa114, valid_bwa113, valid_bwa112, valid_bwa111, valid_bwa110, valid_bwa109, valid_bwa108, valid_bwa107, valid_bwa106, valid_bwa105, valid_bwa104, valid_bwa103, valid_bwa102, valid_bwa101, valid_bwa100, valid_bwa99, valid_bwa98, valid_bwa97, valid_bwa96, valid_bwa95, valid_bwa94, valid_bwa93, valid_bwa92, valid_bwa91, valid_bwa90, valid_bwa89, valid_bwa88, valid_bwa87, valid_bwa86, valid_bwa85, valid_bwa84, valid_bwa83, valid_bwa82, valid_bwa81, valid_bwa80, valid_bwa79, valid_bwa78, valid_bwa77, valid_bwa76, valid_bwa75, valid_bwa74, valid_bwa73, valid_bwa72, valid_bwa71, valid_bwa70, valid_bwa69, valid_bwa68, valid_bwa67, valid_bwa66, valid_bwa65, valid_bwa64, valid_bwa63, valid_bwa62, valid_bwa61, valid_bwa60, valid_bwa59, valid_bwa58, valid_bwa57, valid_bwa56, valid_bwa55, valid_bwa54, valid_bwa53, valid_bwa52, valid_bwa51, valid_bwa50, valid_bwa49, valid_bwa48, valid_bwa47, valid_bwa46, valid_bwa45, valid_bwa44, valid_bwa43, valid_bwa42, valid_bwa41, valid_bwa40, valid_bwa39, valid_bwa38, valid_bwa37, valid_bwa36, valid_bwa35, valid_bwa34, valid_bwa33, valid_bwa32, valid_bwa31, valid_bwa30, valid_bwa29, valid_bwa28, valid_bwa27, valid_bwa26, valid_bwa25, valid_bwa24, valid_bwa23, valid_bwa22, valid_bwa21, valid_bwa20, valid_bwa19, valid_bwa18, valid_bwa17, valid_bwa16, valid_bwa15, valid_bwa14, valid_bwa13, valid_bwa12, valid_bwa11, valid_bwa10, valid_bwa9, valid_bwa8, valid_bwa7, valid_bwa6, valid_bwa5, valid_bwa4, valid_bwa3, valid_bwa2, valid_bwa1, valid_bwa0;
reg valid_bwb127, valid_bwb126, valid_bwb125, valid_bwb124, valid_bwb123, valid_bwb122, valid_bwb121, valid_bwb120, valid_bwb119, valid_bwb118, valid_bwb117, valid_bwb116, valid_bwb115, valid_bwb114, valid_bwb113, valid_bwb112, valid_bwb111, valid_bwb110, valid_bwb109, valid_bwb108, valid_bwb107, valid_bwb106, valid_bwb105, valid_bwb104, valid_bwb103, valid_bwb102, valid_bwb101, valid_bwb100, valid_bwb99, valid_bwb98, valid_bwb97, valid_bwb96, valid_bwb95, valid_bwb94, valid_bwb93, valid_bwb92, valid_bwb91, valid_bwb90, valid_bwb89, valid_bwb88, valid_bwb87, valid_bwb86, valid_bwb85, valid_bwb84, valid_bwb83, valid_bwb82, valid_bwb81, valid_bwb80, valid_bwb79, valid_bwb78, valid_bwb77, valid_bwb76, valid_bwb75, valid_bwb74, valid_bwb73, valid_bwb72, valid_bwb71, valid_bwb70, valid_bwb69, valid_bwb68, valid_bwb67, valid_bwb66, valid_bwb65, valid_bwb64, valid_bwb63, valid_bwb62, valid_bwb61, valid_bwb60, valid_bwb59, valid_bwb58, valid_bwb57, valid_bwb56, valid_bwb55, valid_bwb54, valid_bwb53, valid_bwb52, valid_bwb51, valid_bwb50, valid_bwb49, valid_bwb48, valid_bwb47, valid_bwb46, valid_bwb45, valid_bwb44, valid_bwb43, valid_bwb42, valid_bwb41, valid_bwb40, valid_bwb39, valid_bwb38, valid_bwb37, valid_bwb36, valid_bwb35, valid_bwb34, valid_bwb33, valid_bwb32, valid_bwb31, valid_bwb30, valid_bwb29, valid_bwb28, valid_bwb27, valid_bwb26, valid_bwb25, valid_bwb24, valid_bwb23, valid_bwb22, valid_bwb21, valid_bwb20, valid_bwb19, valid_bwb18, valid_bwb17, valid_bwb16, valid_bwb15, valid_bwb14, valid_bwb13, valid_bwb12, valid_bwb11, valid_bwb10, valid_bwb9, valid_bwb8, valid_bwb7, valid_bwb6, valid_bwb5, valid_bwb4, valid_bwb3, valid_bwb2, valid_bwb1, valid_bwb0;
 
reg EN;
reg RDA, RDB;

reg RCLKA,RCLKB;


wire [1:0] bRTSEL;
wire [1:0] bWTSEL;
wire [1:0] bPTSEL;


wire [N-1:0] bBWEBA;
wire [N-1:0] bBWEBB;
 
wire [N-1:0] bDA;
wire [N-1:0] bDB;
 
wire [M-1:0] bAA;
wire [M-1:0] bAB;
wire [RA-1:0] rowAA;
wire [RA-1:0] rowAB;
 
wire bWEBA,bWEBB;
wire bCEBA,bCEBB;
wire bCLKA,bCLKB;
 
reg [N-1:0] bQA;
reg [N-1:0] bQB;

wire bBIST;
wire WEA,WEB,CSA,CSB;
wire bAWT;
reg valid_awt_wk;
wire iCEBA = bCEBA;
wire iCEBB = bCEBB;
wire iCLKA = bCLKA;
wire iCLKB = bCLKB;
wire [N-1:0] iBWEBA = bBWEBA;
wire [N-1:0] iBWEBB = bBWEBB;

wire [N-1:0] bbQA;
wire [N-1:0] bbQB;
 
integer i;
integer clk_count;
integer sd_mode;




// Address Inputs
buf sAA0 (bAA[0], AA[0]);
buf sAB0 (bAB[0], AB[0]);
buf sAA1 (bAA[1], AA[1]);
buf sAB1 (bAB[1], AB[1]);
buf sAA2 (bAA[2], AA[2]);
buf sAB2 (bAB[2], AB[2]);
buf sAA3 (bAA[3], AA[3]);
buf sAB3 (bAB[3], AB[3]);
buf sAA4 (bAA[4], AA[4]);
buf sAB4 (bAB[4], AB[4]);
buf srAA0 (rowAA[0], AA[2]);
buf srAB0 (rowAB[0], AB[2]);
buf srAA1 (rowAA[1], AA[3]);
buf srAB1 (rowAB[1], AB[3]);
buf srAA2 (rowAA[2], AA[4]);
buf srAB2 (rowAB[2], AB[4]);


// Bit Write/Data Inputs 
buf sDA0 (bDA[0], DA[0]);
buf sDB0 (bDB[0], DB[0]);
buf sDA1 (bDA[1], DA[1]);
buf sDB1 (bDB[1], DB[1]);
buf sDA2 (bDA[2], DA[2]);
buf sDB2 (bDB[2], DB[2]);
buf sDA3 (bDA[3], DA[3]);
buf sDB3 (bDB[3], DB[3]);
buf sDA4 (bDA[4], DA[4]);
buf sDB4 (bDB[4], DB[4]);
buf sDA5 (bDA[5], DA[5]);
buf sDB5 (bDB[5], DB[5]);
buf sDA6 (bDA[6], DA[6]);
buf sDB6 (bDB[6], DB[6]);
buf sDA7 (bDA[7], DA[7]);
buf sDB7 (bDB[7], DB[7]);
buf sDA8 (bDA[8], DA[8]);
buf sDB8 (bDB[8], DB[8]);
buf sDA9 (bDA[9], DA[9]);
buf sDB9 (bDB[9], DB[9]);
buf sDA10 (bDA[10], DA[10]);
buf sDB10 (bDB[10], DB[10]);
buf sDA11 (bDA[11], DA[11]);
buf sDB11 (bDB[11], DB[11]);
buf sDA12 (bDA[12], DA[12]);
buf sDB12 (bDB[12], DB[12]);
buf sDA13 (bDA[13], DA[13]);
buf sDB13 (bDB[13], DB[13]);
buf sDA14 (bDA[14], DA[14]);
buf sDB14 (bDB[14], DB[14]);
buf sDA15 (bDA[15], DA[15]);
buf sDB15 (bDB[15], DB[15]);
buf sDA16 (bDA[16], DA[16]);
buf sDB16 (bDB[16], DB[16]);
buf sDA17 (bDA[17], DA[17]);
buf sDB17 (bDB[17], DB[17]);
buf sDA18 (bDA[18], DA[18]);
buf sDB18 (bDB[18], DB[18]);
buf sDA19 (bDA[19], DA[19]);
buf sDB19 (bDB[19], DB[19]);
buf sDA20 (bDA[20], DA[20]);
buf sDB20 (bDB[20], DB[20]);
buf sDA21 (bDA[21], DA[21]);
buf sDB21 (bDB[21], DB[21]);
buf sDA22 (bDA[22], DA[22]);
buf sDB22 (bDB[22], DB[22]);
buf sDA23 (bDA[23], DA[23]);
buf sDB23 (bDB[23], DB[23]);
buf sDA24 (bDA[24], DA[24]);
buf sDB24 (bDB[24], DB[24]);
buf sDA25 (bDA[25], DA[25]);
buf sDB25 (bDB[25], DB[25]);
buf sDA26 (bDA[26], DA[26]);
buf sDB26 (bDB[26], DB[26]);
buf sDA27 (bDA[27], DA[27]);
buf sDB27 (bDB[27], DB[27]);
buf sDA28 (bDA[28], DA[28]);
buf sDB28 (bDB[28], DB[28]);
buf sDA29 (bDA[29], DA[29]);
buf sDB29 (bDB[29], DB[29]);
buf sDA30 (bDA[30], DA[30]);
buf sDB30 (bDB[30], DB[30]);
buf sDA31 (bDA[31], DA[31]);
buf sDB31 (bDB[31], DB[31]);
buf sDA32 (bDA[32], DA[32]);
buf sDB32 (bDB[32], DB[32]);
buf sDA33 (bDA[33], DA[33]);
buf sDB33 (bDB[33], DB[33]);
buf sDA34 (bDA[34], DA[34]);
buf sDB34 (bDB[34], DB[34]);
buf sDA35 (bDA[35], DA[35]);
buf sDB35 (bDB[35], DB[35]);
buf sDA36 (bDA[36], DA[36]);
buf sDB36 (bDB[36], DB[36]);
buf sDA37 (bDA[37], DA[37]);
buf sDB37 (bDB[37], DB[37]);
buf sDA38 (bDA[38], DA[38]);
buf sDB38 (bDB[38], DB[38]);
buf sDA39 (bDA[39], DA[39]);
buf sDB39 (bDB[39], DB[39]);
buf sDA40 (bDA[40], DA[40]);
buf sDB40 (bDB[40], DB[40]);
buf sDA41 (bDA[41], DA[41]);
buf sDB41 (bDB[41], DB[41]);
buf sDA42 (bDA[42], DA[42]);
buf sDB42 (bDB[42], DB[42]);
buf sDA43 (bDA[43], DA[43]);
buf sDB43 (bDB[43], DB[43]);
buf sDA44 (bDA[44], DA[44]);
buf sDB44 (bDB[44], DB[44]);
buf sDA45 (bDA[45], DA[45]);
buf sDB45 (bDB[45], DB[45]);
buf sDA46 (bDA[46], DA[46]);
buf sDB46 (bDB[46], DB[46]);
buf sDA47 (bDA[47], DA[47]);
buf sDB47 (bDB[47], DB[47]);
buf sDA48 (bDA[48], DA[48]);
buf sDB48 (bDB[48], DB[48]);
buf sDA49 (bDA[49], DA[49]);
buf sDB49 (bDB[49], DB[49]);
buf sDA50 (bDA[50], DA[50]);
buf sDB50 (bDB[50], DB[50]);
buf sDA51 (bDA[51], DA[51]);
buf sDB51 (bDB[51], DB[51]);
buf sDA52 (bDA[52], DA[52]);
buf sDB52 (bDB[52], DB[52]);
buf sDA53 (bDA[53], DA[53]);
buf sDB53 (bDB[53], DB[53]);
buf sDA54 (bDA[54], DA[54]);
buf sDB54 (bDB[54], DB[54]);
buf sDA55 (bDA[55], DA[55]);
buf sDB55 (bDB[55], DB[55]);
buf sDA56 (bDA[56], DA[56]);
buf sDB56 (bDB[56], DB[56]);
buf sDA57 (bDA[57], DA[57]);
buf sDB57 (bDB[57], DB[57]);
buf sDA58 (bDA[58], DA[58]);
buf sDB58 (bDB[58], DB[58]);
buf sDA59 (bDA[59], DA[59]);
buf sDB59 (bDB[59], DB[59]);
buf sDA60 (bDA[60], DA[60]);
buf sDB60 (bDB[60], DB[60]);
buf sDA61 (bDA[61], DA[61]);
buf sDB61 (bDB[61], DB[61]);
buf sDA62 (bDA[62], DA[62]);
buf sDB62 (bDB[62], DB[62]);
buf sDA63 (bDA[63], DA[63]);
buf sDB63 (bDB[63], DB[63]);
buf sDA64 (bDA[64], DA[64]);
buf sDB64 (bDB[64], DB[64]);
buf sDA65 (bDA[65], DA[65]);
buf sDB65 (bDB[65], DB[65]);
buf sDA66 (bDA[66], DA[66]);
buf sDB66 (bDB[66], DB[66]);
buf sDA67 (bDA[67], DA[67]);
buf sDB67 (bDB[67], DB[67]);
buf sDA68 (bDA[68], DA[68]);
buf sDB68 (bDB[68], DB[68]);
buf sDA69 (bDA[69], DA[69]);
buf sDB69 (bDB[69], DB[69]);
buf sDA70 (bDA[70], DA[70]);
buf sDB70 (bDB[70], DB[70]);
buf sDA71 (bDA[71], DA[71]);
buf sDB71 (bDB[71], DB[71]);
buf sDA72 (bDA[72], DA[72]);
buf sDB72 (bDB[72], DB[72]);
buf sDA73 (bDA[73], DA[73]);
buf sDB73 (bDB[73], DB[73]);
buf sDA74 (bDA[74], DA[74]);
buf sDB74 (bDB[74], DB[74]);
buf sDA75 (bDA[75], DA[75]);
buf sDB75 (bDB[75], DB[75]);
buf sDA76 (bDA[76], DA[76]);
buf sDB76 (bDB[76], DB[76]);
buf sDA77 (bDA[77], DA[77]);
buf sDB77 (bDB[77], DB[77]);
buf sDA78 (bDA[78], DA[78]);
buf sDB78 (bDB[78], DB[78]);
buf sDA79 (bDA[79], DA[79]);
buf sDB79 (bDB[79], DB[79]);
buf sDA80 (bDA[80], DA[80]);
buf sDB80 (bDB[80], DB[80]);
buf sDA81 (bDA[81], DA[81]);
buf sDB81 (bDB[81], DB[81]);
buf sDA82 (bDA[82], DA[82]);
buf sDB82 (bDB[82], DB[82]);
buf sDA83 (bDA[83], DA[83]);
buf sDB83 (bDB[83], DB[83]);
buf sDA84 (bDA[84], DA[84]);
buf sDB84 (bDB[84], DB[84]);
buf sDA85 (bDA[85], DA[85]);
buf sDB85 (bDB[85], DB[85]);
buf sDA86 (bDA[86], DA[86]);
buf sDB86 (bDB[86], DB[86]);
buf sDA87 (bDA[87], DA[87]);
buf sDB87 (bDB[87], DB[87]);
buf sDA88 (bDA[88], DA[88]);
buf sDB88 (bDB[88], DB[88]);
buf sDA89 (bDA[89], DA[89]);
buf sDB89 (bDB[89], DB[89]);
buf sDA90 (bDA[90], DA[90]);
buf sDB90 (bDB[90], DB[90]);
buf sDA91 (bDA[91], DA[91]);
buf sDB91 (bDB[91], DB[91]);
buf sDA92 (bDA[92], DA[92]);
buf sDB92 (bDB[92], DB[92]);
buf sDA93 (bDA[93], DA[93]);
buf sDB93 (bDB[93], DB[93]);
buf sDA94 (bDA[94], DA[94]);
buf sDB94 (bDB[94], DB[94]);
buf sDA95 (bDA[95], DA[95]);
buf sDB95 (bDB[95], DB[95]);
buf sDA96 (bDA[96], DA[96]);
buf sDB96 (bDB[96], DB[96]);
buf sDA97 (bDA[97], DA[97]);
buf sDB97 (bDB[97], DB[97]);
buf sDA98 (bDA[98], DA[98]);
buf sDB98 (bDB[98], DB[98]);
buf sDA99 (bDA[99], DA[99]);
buf sDB99 (bDB[99], DB[99]);
buf sDA100 (bDA[100], DA[100]);
buf sDB100 (bDB[100], DB[100]);
buf sDA101 (bDA[101], DA[101]);
buf sDB101 (bDB[101], DB[101]);
buf sDA102 (bDA[102], DA[102]);
buf sDB102 (bDB[102], DB[102]);
buf sDA103 (bDA[103], DA[103]);
buf sDB103 (bDB[103], DB[103]);
buf sDA104 (bDA[104], DA[104]);
buf sDB104 (bDB[104], DB[104]);
buf sDA105 (bDA[105], DA[105]);
buf sDB105 (bDB[105], DB[105]);
buf sDA106 (bDA[106], DA[106]);
buf sDB106 (bDB[106], DB[106]);
buf sDA107 (bDA[107], DA[107]);
buf sDB107 (bDB[107], DB[107]);
buf sDA108 (bDA[108], DA[108]);
buf sDB108 (bDB[108], DB[108]);
buf sDA109 (bDA[109], DA[109]);
buf sDB109 (bDB[109], DB[109]);
buf sDA110 (bDA[110], DA[110]);
buf sDB110 (bDB[110], DB[110]);
buf sDA111 (bDA[111], DA[111]);
buf sDB111 (bDB[111], DB[111]);
buf sDA112 (bDA[112], DA[112]);
buf sDB112 (bDB[112], DB[112]);
buf sDA113 (bDA[113], DA[113]);
buf sDB113 (bDB[113], DB[113]);
buf sDA114 (bDA[114], DA[114]);
buf sDB114 (bDB[114], DB[114]);
buf sDA115 (bDA[115], DA[115]);
buf sDB115 (bDB[115], DB[115]);
buf sDA116 (bDA[116], DA[116]);
buf sDB116 (bDB[116], DB[116]);
buf sDA117 (bDA[117], DA[117]);
buf sDB117 (bDB[117], DB[117]);
buf sDA118 (bDA[118], DA[118]);
buf sDB118 (bDB[118], DB[118]);
buf sDA119 (bDA[119], DA[119]);
buf sDB119 (bDB[119], DB[119]);
buf sDA120 (bDA[120], DA[120]);
buf sDB120 (bDB[120], DB[120]);
buf sDA121 (bDA[121], DA[121]);
buf sDB121 (bDB[121], DB[121]);
buf sDA122 (bDA[122], DA[122]);
buf sDB122 (bDB[122], DB[122]);
buf sDA123 (bDA[123], DA[123]);
buf sDB123 (bDB[123], DB[123]);
buf sDA124 (bDA[124], DA[124]);
buf sDB124 (bDB[124], DB[124]);
buf sDA125 (bDA[125], DA[125]);
buf sDB125 (bDB[125], DB[125]);
buf sDA126 (bDA[126], DA[126]);
buf sDB126 (bDB[126], DB[126]);
buf sDA127 (bDA[127], DA[127]);
buf sDB127 (bDB[127], DB[127]);


buf sBWEBA0 (bBWEBA[0], BWEBA[0]);
buf sBWEBB0 (bBWEBB[0], BWEBB[0]);
buf sBWEBA1 (bBWEBA[1], BWEBA[1]);
buf sBWEBB1 (bBWEBB[1], BWEBB[1]);
buf sBWEBA2 (bBWEBA[2], BWEBA[2]);
buf sBWEBB2 (bBWEBB[2], BWEBB[2]);
buf sBWEBA3 (bBWEBA[3], BWEBA[3]);
buf sBWEBB3 (bBWEBB[3], BWEBB[3]);
buf sBWEBA4 (bBWEBA[4], BWEBA[4]);
buf sBWEBB4 (bBWEBB[4], BWEBB[4]);
buf sBWEBA5 (bBWEBA[5], BWEBA[5]);
buf sBWEBB5 (bBWEBB[5], BWEBB[5]);
buf sBWEBA6 (bBWEBA[6], BWEBA[6]);
buf sBWEBB6 (bBWEBB[6], BWEBB[6]);
buf sBWEBA7 (bBWEBA[7], BWEBA[7]);
buf sBWEBB7 (bBWEBB[7], BWEBB[7]);
buf sBWEBA8 (bBWEBA[8], BWEBA[8]);
buf sBWEBB8 (bBWEBB[8], BWEBB[8]);
buf sBWEBA9 (bBWEBA[9], BWEBA[9]);
buf sBWEBB9 (bBWEBB[9], BWEBB[9]);
buf sBWEBA10 (bBWEBA[10], BWEBA[10]);
buf sBWEBB10 (bBWEBB[10], BWEBB[10]);
buf sBWEBA11 (bBWEBA[11], BWEBA[11]);
buf sBWEBB11 (bBWEBB[11], BWEBB[11]);
buf sBWEBA12 (bBWEBA[12], BWEBA[12]);
buf sBWEBB12 (bBWEBB[12], BWEBB[12]);
buf sBWEBA13 (bBWEBA[13], BWEBA[13]);
buf sBWEBB13 (bBWEBB[13], BWEBB[13]);
buf sBWEBA14 (bBWEBA[14], BWEBA[14]);
buf sBWEBB14 (bBWEBB[14], BWEBB[14]);
buf sBWEBA15 (bBWEBA[15], BWEBA[15]);
buf sBWEBB15 (bBWEBB[15], BWEBB[15]);
buf sBWEBA16 (bBWEBA[16], BWEBA[16]);
buf sBWEBB16 (bBWEBB[16], BWEBB[16]);
buf sBWEBA17 (bBWEBA[17], BWEBA[17]);
buf sBWEBB17 (bBWEBB[17], BWEBB[17]);
buf sBWEBA18 (bBWEBA[18], BWEBA[18]);
buf sBWEBB18 (bBWEBB[18], BWEBB[18]);
buf sBWEBA19 (bBWEBA[19], BWEBA[19]);
buf sBWEBB19 (bBWEBB[19], BWEBB[19]);
buf sBWEBA20 (bBWEBA[20], BWEBA[20]);
buf sBWEBB20 (bBWEBB[20], BWEBB[20]);
buf sBWEBA21 (bBWEBA[21], BWEBA[21]);
buf sBWEBB21 (bBWEBB[21], BWEBB[21]);
buf sBWEBA22 (bBWEBA[22], BWEBA[22]);
buf sBWEBB22 (bBWEBB[22], BWEBB[22]);
buf sBWEBA23 (bBWEBA[23], BWEBA[23]);
buf sBWEBB23 (bBWEBB[23], BWEBB[23]);
buf sBWEBA24 (bBWEBA[24], BWEBA[24]);
buf sBWEBB24 (bBWEBB[24], BWEBB[24]);
buf sBWEBA25 (bBWEBA[25], BWEBA[25]);
buf sBWEBB25 (bBWEBB[25], BWEBB[25]);
buf sBWEBA26 (bBWEBA[26], BWEBA[26]);
buf sBWEBB26 (bBWEBB[26], BWEBB[26]);
buf sBWEBA27 (bBWEBA[27], BWEBA[27]);
buf sBWEBB27 (bBWEBB[27], BWEBB[27]);
buf sBWEBA28 (bBWEBA[28], BWEBA[28]);
buf sBWEBB28 (bBWEBB[28], BWEBB[28]);
buf sBWEBA29 (bBWEBA[29], BWEBA[29]);
buf sBWEBB29 (bBWEBB[29], BWEBB[29]);
buf sBWEBA30 (bBWEBA[30], BWEBA[30]);
buf sBWEBB30 (bBWEBB[30], BWEBB[30]);
buf sBWEBA31 (bBWEBA[31], BWEBA[31]);
buf sBWEBB31 (bBWEBB[31], BWEBB[31]);
buf sBWEBA32 (bBWEBA[32], BWEBA[32]);
buf sBWEBB32 (bBWEBB[32], BWEBB[32]);
buf sBWEBA33 (bBWEBA[33], BWEBA[33]);
buf sBWEBB33 (bBWEBB[33], BWEBB[33]);
buf sBWEBA34 (bBWEBA[34], BWEBA[34]);
buf sBWEBB34 (bBWEBB[34], BWEBB[34]);
buf sBWEBA35 (bBWEBA[35], BWEBA[35]);
buf sBWEBB35 (bBWEBB[35], BWEBB[35]);
buf sBWEBA36 (bBWEBA[36], BWEBA[36]);
buf sBWEBB36 (bBWEBB[36], BWEBB[36]);
buf sBWEBA37 (bBWEBA[37], BWEBA[37]);
buf sBWEBB37 (bBWEBB[37], BWEBB[37]);
buf sBWEBA38 (bBWEBA[38], BWEBA[38]);
buf sBWEBB38 (bBWEBB[38], BWEBB[38]);
buf sBWEBA39 (bBWEBA[39], BWEBA[39]);
buf sBWEBB39 (bBWEBB[39], BWEBB[39]);
buf sBWEBA40 (bBWEBA[40], BWEBA[40]);
buf sBWEBB40 (bBWEBB[40], BWEBB[40]);
buf sBWEBA41 (bBWEBA[41], BWEBA[41]);
buf sBWEBB41 (bBWEBB[41], BWEBB[41]);
buf sBWEBA42 (bBWEBA[42], BWEBA[42]);
buf sBWEBB42 (bBWEBB[42], BWEBB[42]);
buf sBWEBA43 (bBWEBA[43], BWEBA[43]);
buf sBWEBB43 (bBWEBB[43], BWEBB[43]);
buf sBWEBA44 (bBWEBA[44], BWEBA[44]);
buf sBWEBB44 (bBWEBB[44], BWEBB[44]);
buf sBWEBA45 (bBWEBA[45], BWEBA[45]);
buf sBWEBB45 (bBWEBB[45], BWEBB[45]);
buf sBWEBA46 (bBWEBA[46], BWEBA[46]);
buf sBWEBB46 (bBWEBB[46], BWEBB[46]);
buf sBWEBA47 (bBWEBA[47], BWEBA[47]);
buf sBWEBB47 (bBWEBB[47], BWEBB[47]);
buf sBWEBA48 (bBWEBA[48], BWEBA[48]);
buf sBWEBB48 (bBWEBB[48], BWEBB[48]);
buf sBWEBA49 (bBWEBA[49], BWEBA[49]);
buf sBWEBB49 (bBWEBB[49], BWEBB[49]);
buf sBWEBA50 (bBWEBA[50], BWEBA[50]);
buf sBWEBB50 (bBWEBB[50], BWEBB[50]);
buf sBWEBA51 (bBWEBA[51], BWEBA[51]);
buf sBWEBB51 (bBWEBB[51], BWEBB[51]);
buf sBWEBA52 (bBWEBA[52], BWEBA[52]);
buf sBWEBB52 (bBWEBB[52], BWEBB[52]);
buf sBWEBA53 (bBWEBA[53], BWEBA[53]);
buf sBWEBB53 (bBWEBB[53], BWEBB[53]);
buf sBWEBA54 (bBWEBA[54], BWEBA[54]);
buf sBWEBB54 (bBWEBB[54], BWEBB[54]);
buf sBWEBA55 (bBWEBA[55], BWEBA[55]);
buf sBWEBB55 (bBWEBB[55], BWEBB[55]);
buf sBWEBA56 (bBWEBA[56], BWEBA[56]);
buf sBWEBB56 (bBWEBB[56], BWEBB[56]);
buf sBWEBA57 (bBWEBA[57], BWEBA[57]);
buf sBWEBB57 (bBWEBB[57], BWEBB[57]);
buf sBWEBA58 (bBWEBA[58], BWEBA[58]);
buf sBWEBB58 (bBWEBB[58], BWEBB[58]);
buf sBWEBA59 (bBWEBA[59], BWEBA[59]);
buf sBWEBB59 (bBWEBB[59], BWEBB[59]);
buf sBWEBA60 (bBWEBA[60], BWEBA[60]);
buf sBWEBB60 (bBWEBB[60], BWEBB[60]);
buf sBWEBA61 (bBWEBA[61], BWEBA[61]);
buf sBWEBB61 (bBWEBB[61], BWEBB[61]);
buf sBWEBA62 (bBWEBA[62], BWEBA[62]);
buf sBWEBB62 (bBWEBB[62], BWEBB[62]);
buf sBWEBA63 (bBWEBA[63], BWEBA[63]);
buf sBWEBB63 (bBWEBB[63], BWEBB[63]);
buf sBWEBA64 (bBWEBA[64], BWEBA[64]);
buf sBWEBB64 (bBWEBB[64], BWEBB[64]);
buf sBWEBA65 (bBWEBA[65], BWEBA[65]);
buf sBWEBB65 (bBWEBB[65], BWEBB[65]);
buf sBWEBA66 (bBWEBA[66], BWEBA[66]);
buf sBWEBB66 (bBWEBB[66], BWEBB[66]);
buf sBWEBA67 (bBWEBA[67], BWEBA[67]);
buf sBWEBB67 (bBWEBB[67], BWEBB[67]);
buf sBWEBA68 (bBWEBA[68], BWEBA[68]);
buf sBWEBB68 (bBWEBB[68], BWEBB[68]);
buf sBWEBA69 (bBWEBA[69], BWEBA[69]);
buf sBWEBB69 (bBWEBB[69], BWEBB[69]);
buf sBWEBA70 (bBWEBA[70], BWEBA[70]);
buf sBWEBB70 (bBWEBB[70], BWEBB[70]);
buf sBWEBA71 (bBWEBA[71], BWEBA[71]);
buf sBWEBB71 (bBWEBB[71], BWEBB[71]);
buf sBWEBA72 (bBWEBA[72], BWEBA[72]);
buf sBWEBB72 (bBWEBB[72], BWEBB[72]);
buf sBWEBA73 (bBWEBA[73], BWEBA[73]);
buf sBWEBB73 (bBWEBB[73], BWEBB[73]);
buf sBWEBA74 (bBWEBA[74], BWEBA[74]);
buf sBWEBB74 (bBWEBB[74], BWEBB[74]);
buf sBWEBA75 (bBWEBA[75], BWEBA[75]);
buf sBWEBB75 (bBWEBB[75], BWEBB[75]);
buf sBWEBA76 (bBWEBA[76], BWEBA[76]);
buf sBWEBB76 (bBWEBB[76], BWEBB[76]);
buf sBWEBA77 (bBWEBA[77], BWEBA[77]);
buf sBWEBB77 (bBWEBB[77], BWEBB[77]);
buf sBWEBA78 (bBWEBA[78], BWEBA[78]);
buf sBWEBB78 (bBWEBB[78], BWEBB[78]);
buf sBWEBA79 (bBWEBA[79], BWEBA[79]);
buf sBWEBB79 (bBWEBB[79], BWEBB[79]);
buf sBWEBA80 (bBWEBA[80], BWEBA[80]);
buf sBWEBB80 (bBWEBB[80], BWEBB[80]);
buf sBWEBA81 (bBWEBA[81], BWEBA[81]);
buf sBWEBB81 (bBWEBB[81], BWEBB[81]);
buf sBWEBA82 (bBWEBA[82], BWEBA[82]);
buf sBWEBB82 (bBWEBB[82], BWEBB[82]);
buf sBWEBA83 (bBWEBA[83], BWEBA[83]);
buf sBWEBB83 (bBWEBB[83], BWEBB[83]);
buf sBWEBA84 (bBWEBA[84], BWEBA[84]);
buf sBWEBB84 (bBWEBB[84], BWEBB[84]);
buf sBWEBA85 (bBWEBA[85], BWEBA[85]);
buf sBWEBB85 (bBWEBB[85], BWEBB[85]);
buf sBWEBA86 (bBWEBA[86], BWEBA[86]);
buf sBWEBB86 (bBWEBB[86], BWEBB[86]);
buf sBWEBA87 (bBWEBA[87], BWEBA[87]);
buf sBWEBB87 (bBWEBB[87], BWEBB[87]);
buf sBWEBA88 (bBWEBA[88], BWEBA[88]);
buf sBWEBB88 (bBWEBB[88], BWEBB[88]);
buf sBWEBA89 (bBWEBA[89], BWEBA[89]);
buf sBWEBB89 (bBWEBB[89], BWEBB[89]);
buf sBWEBA90 (bBWEBA[90], BWEBA[90]);
buf sBWEBB90 (bBWEBB[90], BWEBB[90]);
buf sBWEBA91 (bBWEBA[91], BWEBA[91]);
buf sBWEBB91 (bBWEBB[91], BWEBB[91]);
buf sBWEBA92 (bBWEBA[92], BWEBA[92]);
buf sBWEBB92 (bBWEBB[92], BWEBB[92]);
buf sBWEBA93 (bBWEBA[93], BWEBA[93]);
buf sBWEBB93 (bBWEBB[93], BWEBB[93]);
buf sBWEBA94 (bBWEBA[94], BWEBA[94]);
buf sBWEBB94 (bBWEBB[94], BWEBB[94]);
buf sBWEBA95 (bBWEBA[95], BWEBA[95]);
buf sBWEBB95 (bBWEBB[95], BWEBB[95]);
buf sBWEBA96 (bBWEBA[96], BWEBA[96]);
buf sBWEBB96 (bBWEBB[96], BWEBB[96]);
buf sBWEBA97 (bBWEBA[97], BWEBA[97]);
buf sBWEBB97 (bBWEBB[97], BWEBB[97]);
buf sBWEBA98 (bBWEBA[98], BWEBA[98]);
buf sBWEBB98 (bBWEBB[98], BWEBB[98]);
buf sBWEBA99 (bBWEBA[99], BWEBA[99]);
buf sBWEBB99 (bBWEBB[99], BWEBB[99]);
buf sBWEBA100 (bBWEBA[100], BWEBA[100]);
buf sBWEBB100 (bBWEBB[100], BWEBB[100]);
buf sBWEBA101 (bBWEBA[101], BWEBA[101]);
buf sBWEBB101 (bBWEBB[101], BWEBB[101]);
buf sBWEBA102 (bBWEBA[102], BWEBA[102]);
buf sBWEBB102 (bBWEBB[102], BWEBB[102]);
buf sBWEBA103 (bBWEBA[103], BWEBA[103]);
buf sBWEBB103 (bBWEBB[103], BWEBB[103]);
buf sBWEBA104 (bBWEBA[104], BWEBA[104]);
buf sBWEBB104 (bBWEBB[104], BWEBB[104]);
buf sBWEBA105 (bBWEBA[105], BWEBA[105]);
buf sBWEBB105 (bBWEBB[105], BWEBB[105]);
buf sBWEBA106 (bBWEBA[106], BWEBA[106]);
buf sBWEBB106 (bBWEBB[106], BWEBB[106]);
buf sBWEBA107 (bBWEBA[107], BWEBA[107]);
buf sBWEBB107 (bBWEBB[107], BWEBB[107]);
buf sBWEBA108 (bBWEBA[108], BWEBA[108]);
buf sBWEBB108 (bBWEBB[108], BWEBB[108]);
buf sBWEBA109 (bBWEBA[109], BWEBA[109]);
buf sBWEBB109 (bBWEBB[109], BWEBB[109]);
buf sBWEBA110 (bBWEBA[110], BWEBA[110]);
buf sBWEBB110 (bBWEBB[110], BWEBB[110]);
buf sBWEBA111 (bBWEBA[111], BWEBA[111]);
buf sBWEBB111 (bBWEBB[111], BWEBB[111]);
buf sBWEBA112 (bBWEBA[112], BWEBA[112]);
buf sBWEBB112 (bBWEBB[112], BWEBB[112]);
buf sBWEBA113 (bBWEBA[113], BWEBA[113]);
buf sBWEBB113 (bBWEBB[113], BWEBB[113]);
buf sBWEBA114 (bBWEBA[114], BWEBA[114]);
buf sBWEBB114 (bBWEBB[114], BWEBB[114]);
buf sBWEBA115 (bBWEBA[115], BWEBA[115]);
buf sBWEBB115 (bBWEBB[115], BWEBB[115]);
buf sBWEBA116 (bBWEBA[116], BWEBA[116]);
buf sBWEBB116 (bBWEBB[116], BWEBB[116]);
buf sBWEBA117 (bBWEBA[117], BWEBA[117]);
buf sBWEBB117 (bBWEBB[117], BWEBB[117]);
buf sBWEBA118 (bBWEBA[118], BWEBA[118]);
buf sBWEBB118 (bBWEBB[118], BWEBB[118]);
buf sBWEBA119 (bBWEBA[119], BWEBA[119]);
buf sBWEBB119 (bBWEBB[119], BWEBB[119]);
buf sBWEBA120 (bBWEBA[120], BWEBA[120]);
buf sBWEBB120 (bBWEBB[120], BWEBB[120]);
buf sBWEBA121 (bBWEBA[121], BWEBA[121]);
buf sBWEBB121 (bBWEBB[121], BWEBB[121]);
buf sBWEBA122 (bBWEBA[122], BWEBA[122]);
buf sBWEBB122 (bBWEBB[122], BWEBB[122]);
buf sBWEBA123 (bBWEBA[123], BWEBA[123]);
buf sBWEBB123 (bBWEBB[123], BWEBB[123]);
buf sBWEBA124 (bBWEBA[124], BWEBA[124]);
buf sBWEBB124 (bBWEBB[124], BWEBB[124]);
buf sBWEBA125 (bBWEBA[125], BWEBA[125]);
buf sBWEBB125 (bBWEBB[125], BWEBB[125]);
buf sBWEBA126 (bBWEBA[126], BWEBA[126]);
buf sBWEBB126 (bBWEBB[126], BWEBB[126]);
buf sBWEBA127 (bBWEBA[127], BWEBA[127]);
buf sBWEBB127 (bBWEBB[127], BWEBB[127]);


// Input Controls
buf sWEBA (bWEBA, WEBA);
buf sWEBB (bWEBB, WEBB);
wire bSLP = 1'b0;
wire bDSLP = 1'b0;
wire bSD = 1'b0;
 
buf sCEBA (bCEBA, CEBA);
buf sCEBB (bCEBB, CEBB);
 
buf sCLKA (bCLKA, CLK);
buf sCLKB (bCLKB, CLK);
buf sAWT (bAWT, AWT);
assign bBIST = 1'b0;

buf sRTSEL0 (bRTSEL[0], RTSEL[0]);
buf sRTSEL1 (bRTSEL[1], RTSEL[1]);
buf sWTSEL0 (bWTSEL[0], WTSEL[0]);
buf sWTSEL1 (bWTSEL[1], WTSEL[1]);
buf sPTSEL0 (bPTSEL[0], PTSEL[0]);
buf sPTSEL1 (bPTSEL[1], PTSEL[1]);

// Output Data
buf sQA0 (QA[0], bbQA[0]);
buf sQA1 (QA[1], bbQA[1]);
buf sQA2 (QA[2], bbQA[2]);
buf sQA3 (QA[3], bbQA[3]);
buf sQA4 (QA[4], bbQA[4]);
buf sQA5 (QA[5], bbQA[5]);
buf sQA6 (QA[6], bbQA[6]);
buf sQA7 (QA[7], bbQA[7]);
buf sQA8 (QA[8], bbQA[8]);
buf sQA9 (QA[9], bbQA[9]);
buf sQA10 (QA[10], bbQA[10]);
buf sQA11 (QA[11], bbQA[11]);
buf sQA12 (QA[12], bbQA[12]);
buf sQA13 (QA[13], bbQA[13]);
buf sQA14 (QA[14], bbQA[14]);
buf sQA15 (QA[15], bbQA[15]);
buf sQA16 (QA[16], bbQA[16]);
buf sQA17 (QA[17], bbQA[17]);
buf sQA18 (QA[18], bbQA[18]);
buf sQA19 (QA[19], bbQA[19]);
buf sQA20 (QA[20], bbQA[20]);
buf sQA21 (QA[21], bbQA[21]);
buf sQA22 (QA[22], bbQA[22]);
buf sQA23 (QA[23], bbQA[23]);
buf sQA24 (QA[24], bbQA[24]);
buf sQA25 (QA[25], bbQA[25]);
buf sQA26 (QA[26], bbQA[26]);
buf sQA27 (QA[27], bbQA[27]);
buf sQA28 (QA[28], bbQA[28]);
buf sQA29 (QA[29], bbQA[29]);
buf sQA30 (QA[30], bbQA[30]);
buf sQA31 (QA[31], bbQA[31]);
buf sQA32 (QA[32], bbQA[32]);
buf sQA33 (QA[33], bbQA[33]);
buf sQA34 (QA[34], bbQA[34]);
buf sQA35 (QA[35], bbQA[35]);
buf sQA36 (QA[36], bbQA[36]);
buf sQA37 (QA[37], bbQA[37]);
buf sQA38 (QA[38], bbQA[38]);
buf sQA39 (QA[39], bbQA[39]);
buf sQA40 (QA[40], bbQA[40]);
buf sQA41 (QA[41], bbQA[41]);
buf sQA42 (QA[42], bbQA[42]);
buf sQA43 (QA[43], bbQA[43]);
buf sQA44 (QA[44], bbQA[44]);
buf sQA45 (QA[45], bbQA[45]);
buf sQA46 (QA[46], bbQA[46]);
buf sQA47 (QA[47], bbQA[47]);
buf sQA48 (QA[48], bbQA[48]);
buf sQA49 (QA[49], bbQA[49]);
buf sQA50 (QA[50], bbQA[50]);
buf sQA51 (QA[51], bbQA[51]);
buf sQA52 (QA[52], bbQA[52]);
buf sQA53 (QA[53], bbQA[53]);
buf sQA54 (QA[54], bbQA[54]);
buf sQA55 (QA[55], bbQA[55]);
buf sQA56 (QA[56], bbQA[56]);
buf sQA57 (QA[57], bbQA[57]);
buf sQA58 (QA[58], bbQA[58]);
buf sQA59 (QA[59], bbQA[59]);
buf sQA60 (QA[60], bbQA[60]);
buf sQA61 (QA[61], bbQA[61]);
buf sQA62 (QA[62], bbQA[62]);
buf sQA63 (QA[63], bbQA[63]);
buf sQA64 (QA[64], bbQA[64]);
buf sQA65 (QA[65], bbQA[65]);
buf sQA66 (QA[66], bbQA[66]);
buf sQA67 (QA[67], bbQA[67]);
buf sQA68 (QA[68], bbQA[68]);
buf sQA69 (QA[69], bbQA[69]);
buf sQA70 (QA[70], bbQA[70]);
buf sQA71 (QA[71], bbQA[71]);
buf sQA72 (QA[72], bbQA[72]);
buf sQA73 (QA[73], bbQA[73]);
buf sQA74 (QA[74], bbQA[74]);
buf sQA75 (QA[75], bbQA[75]);
buf sQA76 (QA[76], bbQA[76]);
buf sQA77 (QA[77], bbQA[77]);
buf sQA78 (QA[78], bbQA[78]);
buf sQA79 (QA[79], bbQA[79]);
buf sQA80 (QA[80], bbQA[80]);
buf sQA81 (QA[81], bbQA[81]);
buf sQA82 (QA[82], bbQA[82]);
buf sQA83 (QA[83], bbQA[83]);
buf sQA84 (QA[84], bbQA[84]);
buf sQA85 (QA[85], bbQA[85]);
buf sQA86 (QA[86], bbQA[86]);
buf sQA87 (QA[87], bbQA[87]);
buf sQA88 (QA[88], bbQA[88]);
buf sQA89 (QA[89], bbQA[89]);
buf sQA90 (QA[90], bbQA[90]);
buf sQA91 (QA[91], bbQA[91]);
buf sQA92 (QA[92], bbQA[92]);
buf sQA93 (QA[93], bbQA[93]);
buf sQA94 (QA[94], bbQA[94]);
buf sQA95 (QA[95], bbQA[95]);
buf sQA96 (QA[96], bbQA[96]);
buf sQA97 (QA[97], bbQA[97]);
buf sQA98 (QA[98], bbQA[98]);
buf sQA99 (QA[99], bbQA[99]);
buf sQA100 (QA[100], bbQA[100]);
buf sQA101 (QA[101], bbQA[101]);
buf sQA102 (QA[102], bbQA[102]);
buf sQA103 (QA[103], bbQA[103]);
buf sQA104 (QA[104], bbQA[104]);
buf sQA105 (QA[105], bbQA[105]);
buf sQA106 (QA[106], bbQA[106]);
buf sQA107 (QA[107], bbQA[107]);
buf sQA108 (QA[108], bbQA[108]);
buf sQA109 (QA[109], bbQA[109]);
buf sQA110 (QA[110], bbQA[110]);
buf sQA111 (QA[111], bbQA[111]);
buf sQA112 (QA[112], bbQA[112]);
buf sQA113 (QA[113], bbQA[113]);
buf sQA114 (QA[114], bbQA[114]);
buf sQA115 (QA[115], bbQA[115]);
buf sQA116 (QA[116], bbQA[116]);
buf sQA117 (QA[117], bbQA[117]);
buf sQA118 (QA[118], bbQA[118]);
buf sQA119 (QA[119], bbQA[119]);
buf sQA120 (QA[120], bbQA[120]);
buf sQA121 (QA[121], bbQA[121]);
buf sQA122 (QA[122], bbQA[122]);
buf sQA123 (QA[123], bbQA[123]);
buf sQA124 (QA[124], bbQA[124]);
buf sQA125 (QA[125], bbQA[125]);
buf sQA126 (QA[126], bbQA[126]);
buf sQA127 (QA[127], bbQA[127]);

buf sQB0 (QB[0], bbQB[0]);
buf sQB1 (QB[1], bbQB[1]);
buf sQB2 (QB[2], bbQB[2]);
buf sQB3 (QB[3], bbQB[3]);
buf sQB4 (QB[4], bbQB[4]);
buf sQB5 (QB[5], bbQB[5]);
buf sQB6 (QB[6], bbQB[6]);
buf sQB7 (QB[7], bbQB[7]);
buf sQB8 (QB[8], bbQB[8]);
buf sQB9 (QB[9], bbQB[9]);
buf sQB10 (QB[10], bbQB[10]);
buf sQB11 (QB[11], bbQB[11]);
buf sQB12 (QB[12], bbQB[12]);
buf sQB13 (QB[13], bbQB[13]);
buf sQB14 (QB[14], bbQB[14]);
buf sQB15 (QB[15], bbQB[15]);
buf sQB16 (QB[16], bbQB[16]);
buf sQB17 (QB[17], bbQB[17]);
buf sQB18 (QB[18], bbQB[18]);
buf sQB19 (QB[19], bbQB[19]);
buf sQB20 (QB[20], bbQB[20]);
buf sQB21 (QB[21], bbQB[21]);
buf sQB22 (QB[22], bbQB[22]);
buf sQB23 (QB[23], bbQB[23]);
buf sQB24 (QB[24], bbQB[24]);
buf sQB25 (QB[25], bbQB[25]);
buf sQB26 (QB[26], bbQB[26]);
buf sQB27 (QB[27], bbQB[27]);
buf sQB28 (QB[28], bbQB[28]);
buf sQB29 (QB[29], bbQB[29]);
buf sQB30 (QB[30], bbQB[30]);
buf sQB31 (QB[31], bbQB[31]);
buf sQB32 (QB[32], bbQB[32]);
buf sQB33 (QB[33], bbQB[33]);
buf sQB34 (QB[34], bbQB[34]);
buf sQB35 (QB[35], bbQB[35]);
buf sQB36 (QB[36], bbQB[36]);
buf sQB37 (QB[37], bbQB[37]);
buf sQB38 (QB[38], bbQB[38]);
buf sQB39 (QB[39], bbQB[39]);
buf sQB40 (QB[40], bbQB[40]);
buf sQB41 (QB[41], bbQB[41]);
buf sQB42 (QB[42], bbQB[42]);
buf sQB43 (QB[43], bbQB[43]);
buf sQB44 (QB[44], bbQB[44]);
buf sQB45 (QB[45], bbQB[45]);
buf sQB46 (QB[46], bbQB[46]);
buf sQB47 (QB[47], bbQB[47]);
buf sQB48 (QB[48], bbQB[48]);
buf sQB49 (QB[49], bbQB[49]);
buf sQB50 (QB[50], bbQB[50]);
buf sQB51 (QB[51], bbQB[51]);
buf sQB52 (QB[52], bbQB[52]);
buf sQB53 (QB[53], bbQB[53]);
buf sQB54 (QB[54], bbQB[54]);
buf sQB55 (QB[55], bbQB[55]);
buf sQB56 (QB[56], bbQB[56]);
buf sQB57 (QB[57], bbQB[57]);
buf sQB58 (QB[58], bbQB[58]);
buf sQB59 (QB[59], bbQB[59]);
buf sQB60 (QB[60], bbQB[60]);
buf sQB61 (QB[61], bbQB[61]);
buf sQB62 (QB[62], bbQB[62]);
buf sQB63 (QB[63], bbQB[63]);
buf sQB64 (QB[64], bbQB[64]);
buf sQB65 (QB[65], bbQB[65]);
buf sQB66 (QB[66], bbQB[66]);
buf sQB67 (QB[67], bbQB[67]);
buf sQB68 (QB[68], bbQB[68]);
buf sQB69 (QB[69], bbQB[69]);
buf sQB70 (QB[70], bbQB[70]);
buf sQB71 (QB[71], bbQB[71]);
buf sQB72 (QB[72], bbQB[72]);
buf sQB73 (QB[73], bbQB[73]);
buf sQB74 (QB[74], bbQB[74]);
buf sQB75 (QB[75], bbQB[75]);
buf sQB76 (QB[76], bbQB[76]);
buf sQB77 (QB[77], bbQB[77]);
buf sQB78 (QB[78], bbQB[78]);
buf sQB79 (QB[79], bbQB[79]);
buf sQB80 (QB[80], bbQB[80]);
buf sQB81 (QB[81], bbQB[81]);
buf sQB82 (QB[82], bbQB[82]);
buf sQB83 (QB[83], bbQB[83]);
buf sQB84 (QB[84], bbQB[84]);
buf sQB85 (QB[85], bbQB[85]);
buf sQB86 (QB[86], bbQB[86]);
buf sQB87 (QB[87], bbQB[87]);
buf sQB88 (QB[88], bbQB[88]);
buf sQB89 (QB[89], bbQB[89]);
buf sQB90 (QB[90], bbQB[90]);
buf sQB91 (QB[91], bbQB[91]);
buf sQB92 (QB[92], bbQB[92]);
buf sQB93 (QB[93], bbQB[93]);
buf sQB94 (QB[94], bbQB[94]);
buf sQB95 (QB[95], bbQB[95]);
buf sQB96 (QB[96], bbQB[96]);
buf sQB97 (QB[97], bbQB[97]);
buf sQB98 (QB[98], bbQB[98]);
buf sQB99 (QB[99], bbQB[99]);
buf sQB100 (QB[100], bbQB[100]);
buf sQB101 (QB[101], bbQB[101]);
buf sQB102 (QB[102], bbQB[102]);
buf sQB103 (QB[103], bbQB[103]);
buf sQB104 (QB[104], bbQB[104]);
buf sQB105 (QB[105], bbQB[105]);
buf sQB106 (QB[106], bbQB[106]);
buf sQB107 (QB[107], bbQB[107]);
buf sQB108 (QB[108], bbQB[108]);
buf sQB109 (QB[109], bbQB[109]);
buf sQB110 (QB[110], bbQB[110]);
buf sQB111 (QB[111], bbQB[111]);
buf sQB112 (QB[112], bbQB[112]);
buf sQB113 (QB[113], bbQB[113]);
buf sQB114 (QB[114], bbQB[114]);
buf sQB115 (QB[115], bbQB[115]);
buf sQB116 (QB[116], bbQB[116]);
buf sQB117 (QB[117], bbQB[117]);
buf sQB118 (QB[118], bbQB[118]);
buf sQB119 (QB[119], bbQB[119]);
buf sQB120 (QB[120], bbQB[120]);
buf sQB121 (QB[121], bbQB[121]);
buf sQB122 (QB[122], bbQB[122]);
buf sQB123 (QB[123], bbQB[123]);
buf sQB124 (QB[124], bbQB[124]);
buf sQB125 (QB[125], bbQB[125]);
buf sQB126 (QB[126], bbQB[126]);
buf sQB127 (QB[127], bbQB[127]);

assign bbQA=bQA;
assign bbQB=bQB;

//and sWEA (WEA, !bWEBA, !bCEBA);
//and sWEB (WEB, !bWEBB, !bCEBB);
assign WEA = !bSLP & !bDSLP & !bSD & !bCEBA & !bWEBA;
assign WEB = !bSLP & !bDSLP & !bSD & !bCEBB & !bWEBB;

//buf sCSA (CSA, !bCEBA);
//buf sCSB (CSB, !bCEBB);
assign CSA = !bSLP & !bDSLP & !bSD & !bCEBA;
assign CSB = !bSLP & !bDSLP & !bSD & !bCEBB;

wire check_noidle_b = ~CEBBL & ~bSD & ~bDSLP & ~bSLP;
wire check_idle_b = CEBBL & ~bSD & ~bDSLP & ~bSLP;
wire check_noidle_a = ~CEBAL & ~bSD & ~bDSLP & ~bSLP;
wire check_idle_a = CEBAL & ~bSD & ~bDSLP & ~bSLP;
wire check_noidle_norm_b = check_noidle_b & ~bBIST;
wire check_noidle_bist_b = check_noidle_b & bBIST;
wire check_idle_norm_b = check_idle_b & ~bBIST;
wire check_idle_bist_b = check_idle_b & bBIST;
wire check_noidle_norm_a = check_noidle_a & ~bBIST;
wire check_noidle_bist_a = check_noidle_a & bBIST;
wire check_idle_norm_a = check_idle_a & !bBIST;
wire check_idle_bist_a = check_idle_a & bBIST;

wire check_ceb  = (~iCEBA | ~iCEBB) & ~bSD & ~bDSLP & ~bSLP;
wire check_ceba = ~iCEBA & ~bSD & ~bDSLP & ~bSLP;
wire check_cebb = ~iCEBB & ~bSD & ~bDSLP & ~bSLP;
wire check_cebm = (~iCEBA | ~iCEBB) & ~bSD & ~bDSLP & ~bSLP;
wire check_ceb_a  = ~iCEBA & iCEBB & ~bSD & ~bDSLP & ~bSLP;
wire check_ceb_b  = iCEBA & ~iCEBB & ~bSD & ~bDSLP & ~bSLP;
wire check_ceb_ab = ~iCEBA & ~iCEBB & ~bSD & ~bDSLP & ~bSLP;





wire check_slp = !bSD & !bDSLP;
wire check_dslp = !bSD & !bSLP;


`ifdef TSMC_CM_UNIT_DELAY
`else
specify
    specparam PATHPULSE$ = ( 0, 0.001 );

specparam
tckl = 0.1389789,
tckh = 0.1389789,
tcyc  = 1.0133780,


taas = 0.0912900,
taah = 0.0878800,
tdas = 0.0179933,
tdah = 0.1203422,
tcas = 0.1207700,
tcah = 0.1032800,
twas = 0.1257567,
twah = 0.0866700,
tbwas = 0.0192644,
tbwah = 0.1200122,

tabs = 0.0100000,
tabh = 0.1032800,
tdbs = 0.0100000,
tdbh = 0.1681556,
tcbs = 0.1207700,
tcbh = 0.1032800,
twbs = 0.0100000,
twbh = 0.1032800,
tbwbs = 0.0100000,
tbwbh = 0.1682167,

ttests = 1.013,
ttesth = 1.013,
tawtq = 0.3535483,
tawtqh = 0.1682433,
tdq = 0.2120600,
tdqh = 0.1113217,
tbwebq = 0.2051856,
tbwebqh = 0.1202372,
tcda   = 0.5058909,
tcdb   = 1.0112320,
`ifdef TSMC_CM_READ_X_SQUASHING
tholda    = 0.5058909,
tholdb    = 1.0112320;
`else
tholda    = 0.3428333,
tholdb    = 0.7576050;
`endif

    $setuphold (posedge CLK &&& check_noidle_a, posedge RTSEL[0], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_a, negedge RTSEL[0], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_a, posedge RTSEL[0], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_a, negedge RTSEL[0], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_a, posedge RTSEL[1], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_a, negedge RTSEL[1], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_a, posedge RTSEL[1], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_a, negedge RTSEL[1], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_a, posedge WTSEL[0], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_a, negedge WTSEL[0], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_a, posedge WTSEL[0], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_a, negedge WTSEL[0], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_a, posedge WTSEL[1], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_a, negedge WTSEL[1], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_a, posedge WTSEL[1], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_a, negedge WTSEL[1], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_a, posedge PTSEL[0], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_a, negedge PTSEL[0], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_a, posedge PTSEL[0], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_a, negedge PTSEL[0], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_a, posedge PTSEL[1], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_a, negedge PTSEL[1], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_a, posedge PTSEL[1], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_a, negedge PTSEL[1], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_b, posedge RTSEL[0], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_b, negedge RTSEL[0], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_b, posedge RTSEL[0], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_b, negedge RTSEL[0], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_b, posedge RTSEL[1], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_b, negedge RTSEL[1], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_b, posedge RTSEL[1], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_b, negedge RTSEL[1], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_b, posedge WTSEL[0], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_b, negedge WTSEL[0], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_b, posedge WTSEL[0], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_b, negedge WTSEL[0], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_b, posedge WTSEL[1], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_b, negedge WTSEL[1], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_b, posedge WTSEL[1], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_b, negedge WTSEL[1], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_b, posedge PTSEL[0], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_b, negedge PTSEL[0], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_b, posedge PTSEL[0], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_b, negedge PTSEL[0], 0, ttesth, valid_testpin);
    $setuphold (posedge CLK &&& check_noidle_b, posedge PTSEL[1], ttests, 0, valid_testpin); 
    $setuphold (posedge CLK &&& check_noidle_b, negedge PTSEL[1], ttests, 0, valid_testpin);
    $setuphold (posedge CLK &&& check_idle_b, posedge PTSEL[1], 0, ttesth, valid_testpin); 
    $setuphold (posedge CLK &&& check_idle_b, negedge PTSEL[1], 0, ttesth, valid_testpin);










    $setuphold (posedge CLK &&& CSA, posedge AA[0], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSA, negedge AA[0], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSB, posedge AB[0], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSB, negedge AB[0], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSA, posedge AA[1], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSA, negedge AA[1], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSB, posedge AB[1], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSB, negedge AB[1], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSA, posedge AA[2], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSA, negedge AA[2], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSB, posedge AB[2], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSB, negedge AB[2], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSA, posedge AA[3], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSA, negedge AA[3], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSB, posedge AB[3], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSB, negedge AB[3], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSA, posedge AA[4], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSA, negedge AA[4], taas, taah, valid_aa);
    $setuphold (posedge CLK &&& CSB, posedge AB[4], tabs, tabh, valid_ab);
    $setuphold (posedge CLK &&& CSB, negedge AB[4], tabs, tabh, valid_ab);

    $setuphold (posedge CLK &&& WEA, posedge DA[0], tdas, tdah, valid_da0);
    $setuphold (posedge CLK &&& WEA, negedge DA[0], tdas, tdah, valid_da0);
    $setuphold (posedge CLK &&& WEB, posedge DB[0], tdbs, tdbh, valid_db0);
    $setuphold (posedge CLK &&& WEB, negedge DB[0], tdbs, tdbh, valid_db0);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[0], tbwas, tbwah, valid_bwa0);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[0], tbwas, tbwah, valid_bwa0);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[0], tbwbs, tbwbh, valid_bwb0);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[0], tbwbs, tbwbh, valid_bwb0);
    $setuphold (posedge CLK &&& WEA, posedge DA[1], tdas, tdah, valid_da1);
    $setuphold (posedge CLK &&& WEA, negedge DA[1], tdas, tdah, valid_da1);
    $setuphold (posedge CLK &&& WEB, posedge DB[1], tdbs, tdbh, valid_db1);
    $setuphold (posedge CLK &&& WEB, negedge DB[1], tdbs, tdbh, valid_db1);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[1], tbwas, tbwah, valid_bwa1);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[1], tbwas, tbwah, valid_bwa1);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[1], tbwbs, tbwbh, valid_bwb1);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[1], tbwbs, tbwbh, valid_bwb1);
    $setuphold (posedge CLK &&& WEA, posedge DA[2], tdas, tdah, valid_da2);
    $setuphold (posedge CLK &&& WEA, negedge DA[2], tdas, tdah, valid_da2);
    $setuphold (posedge CLK &&& WEB, posedge DB[2], tdbs, tdbh, valid_db2);
    $setuphold (posedge CLK &&& WEB, negedge DB[2], tdbs, tdbh, valid_db2);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[2], tbwas, tbwah, valid_bwa2);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[2], tbwas, tbwah, valid_bwa2);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[2], tbwbs, tbwbh, valid_bwb2);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[2], tbwbs, tbwbh, valid_bwb2);
    $setuphold (posedge CLK &&& WEA, posedge DA[3], tdas, tdah, valid_da3);
    $setuphold (posedge CLK &&& WEA, negedge DA[3], tdas, tdah, valid_da3);
    $setuphold (posedge CLK &&& WEB, posedge DB[3], tdbs, tdbh, valid_db3);
    $setuphold (posedge CLK &&& WEB, negedge DB[3], tdbs, tdbh, valid_db3);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[3], tbwas, tbwah, valid_bwa3);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[3], tbwas, tbwah, valid_bwa3);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[3], tbwbs, tbwbh, valid_bwb3);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[3], tbwbs, tbwbh, valid_bwb3);
    $setuphold (posedge CLK &&& WEA, posedge DA[4], tdas, tdah, valid_da4);
    $setuphold (posedge CLK &&& WEA, negedge DA[4], tdas, tdah, valid_da4);
    $setuphold (posedge CLK &&& WEB, posedge DB[4], tdbs, tdbh, valid_db4);
    $setuphold (posedge CLK &&& WEB, negedge DB[4], tdbs, tdbh, valid_db4);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[4], tbwas, tbwah, valid_bwa4);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[4], tbwas, tbwah, valid_bwa4);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[4], tbwbs, tbwbh, valid_bwb4);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[4], tbwbs, tbwbh, valid_bwb4);
    $setuphold (posedge CLK &&& WEA, posedge DA[5], tdas, tdah, valid_da5);
    $setuphold (posedge CLK &&& WEA, negedge DA[5], tdas, tdah, valid_da5);
    $setuphold (posedge CLK &&& WEB, posedge DB[5], tdbs, tdbh, valid_db5);
    $setuphold (posedge CLK &&& WEB, negedge DB[5], tdbs, tdbh, valid_db5);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[5], tbwas, tbwah, valid_bwa5);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[5], tbwas, tbwah, valid_bwa5);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[5], tbwbs, tbwbh, valid_bwb5);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[5], tbwbs, tbwbh, valid_bwb5);
    $setuphold (posedge CLK &&& WEA, posedge DA[6], tdas, tdah, valid_da6);
    $setuphold (posedge CLK &&& WEA, negedge DA[6], tdas, tdah, valid_da6);
    $setuphold (posedge CLK &&& WEB, posedge DB[6], tdbs, tdbh, valid_db6);
    $setuphold (posedge CLK &&& WEB, negedge DB[6], tdbs, tdbh, valid_db6);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[6], tbwas, tbwah, valid_bwa6);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[6], tbwas, tbwah, valid_bwa6);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[6], tbwbs, tbwbh, valid_bwb6);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[6], tbwbs, tbwbh, valid_bwb6);
    $setuphold (posedge CLK &&& WEA, posedge DA[7], tdas, tdah, valid_da7);
    $setuphold (posedge CLK &&& WEA, negedge DA[7], tdas, tdah, valid_da7);
    $setuphold (posedge CLK &&& WEB, posedge DB[7], tdbs, tdbh, valid_db7);
    $setuphold (posedge CLK &&& WEB, negedge DB[7], tdbs, tdbh, valid_db7);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[7], tbwas, tbwah, valid_bwa7);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[7], tbwas, tbwah, valid_bwa7);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[7], tbwbs, tbwbh, valid_bwb7);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[7], tbwbs, tbwbh, valid_bwb7);
    $setuphold (posedge CLK &&& WEA, posedge DA[8], tdas, tdah, valid_da8);
    $setuphold (posedge CLK &&& WEA, negedge DA[8], tdas, tdah, valid_da8);
    $setuphold (posedge CLK &&& WEB, posedge DB[8], tdbs, tdbh, valid_db8);
    $setuphold (posedge CLK &&& WEB, negedge DB[8], tdbs, tdbh, valid_db8);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[8], tbwas, tbwah, valid_bwa8);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[8], tbwas, tbwah, valid_bwa8);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[8], tbwbs, tbwbh, valid_bwb8);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[8], tbwbs, tbwbh, valid_bwb8);
    $setuphold (posedge CLK &&& WEA, posedge DA[9], tdas, tdah, valid_da9);
    $setuphold (posedge CLK &&& WEA, negedge DA[9], tdas, tdah, valid_da9);
    $setuphold (posedge CLK &&& WEB, posedge DB[9], tdbs, tdbh, valid_db9);
    $setuphold (posedge CLK &&& WEB, negedge DB[9], tdbs, tdbh, valid_db9);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[9], tbwas, tbwah, valid_bwa9);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[9], tbwas, tbwah, valid_bwa9);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[9], tbwbs, tbwbh, valid_bwb9);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[9], tbwbs, tbwbh, valid_bwb9);
    $setuphold (posedge CLK &&& WEA, posedge DA[10], tdas, tdah, valid_da10);
    $setuphold (posedge CLK &&& WEA, negedge DA[10], tdas, tdah, valid_da10);
    $setuphold (posedge CLK &&& WEB, posedge DB[10], tdbs, tdbh, valid_db10);
    $setuphold (posedge CLK &&& WEB, negedge DB[10], tdbs, tdbh, valid_db10);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[10], tbwas, tbwah, valid_bwa10);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[10], tbwas, tbwah, valid_bwa10);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[10], tbwbs, tbwbh, valid_bwb10);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[10], tbwbs, tbwbh, valid_bwb10);
    $setuphold (posedge CLK &&& WEA, posedge DA[11], tdas, tdah, valid_da11);
    $setuphold (posedge CLK &&& WEA, negedge DA[11], tdas, tdah, valid_da11);
    $setuphold (posedge CLK &&& WEB, posedge DB[11], tdbs, tdbh, valid_db11);
    $setuphold (posedge CLK &&& WEB, negedge DB[11], tdbs, tdbh, valid_db11);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[11], tbwas, tbwah, valid_bwa11);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[11], tbwas, tbwah, valid_bwa11);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[11], tbwbs, tbwbh, valid_bwb11);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[11], tbwbs, tbwbh, valid_bwb11);
    $setuphold (posedge CLK &&& WEA, posedge DA[12], tdas, tdah, valid_da12);
    $setuphold (posedge CLK &&& WEA, negedge DA[12], tdas, tdah, valid_da12);
    $setuphold (posedge CLK &&& WEB, posedge DB[12], tdbs, tdbh, valid_db12);
    $setuphold (posedge CLK &&& WEB, negedge DB[12], tdbs, tdbh, valid_db12);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[12], tbwas, tbwah, valid_bwa12);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[12], tbwas, tbwah, valid_bwa12);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[12], tbwbs, tbwbh, valid_bwb12);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[12], tbwbs, tbwbh, valid_bwb12);
    $setuphold (posedge CLK &&& WEA, posedge DA[13], tdas, tdah, valid_da13);
    $setuphold (posedge CLK &&& WEA, negedge DA[13], tdas, tdah, valid_da13);
    $setuphold (posedge CLK &&& WEB, posedge DB[13], tdbs, tdbh, valid_db13);
    $setuphold (posedge CLK &&& WEB, negedge DB[13], tdbs, tdbh, valid_db13);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[13], tbwas, tbwah, valid_bwa13);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[13], tbwas, tbwah, valid_bwa13);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[13], tbwbs, tbwbh, valid_bwb13);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[13], tbwbs, tbwbh, valid_bwb13);
    $setuphold (posedge CLK &&& WEA, posedge DA[14], tdas, tdah, valid_da14);
    $setuphold (posedge CLK &&& WEA, negedge DA[14], tdas, tdah, valid_da14);
    $setuphold (posedge CLK &&& WEB, posedge DB[14], tdbs, tdbh, valid_db14);
    $setuphold (posedge CLK &&& WEB, negedge DB[14], tdbs, tdbh, valid_db14);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[14], tbwas, tbwah, valid_bwa14);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[14], tbwas, tbwah, valid_bwa14);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[14], tbwbs, tbwbh, valid_bwb14);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[14], tbwbs, tbwbh, valid_bwb14);
    $setuphold (posedge CLK &&& WEA, posedge DA[15], tdas, tdah, valid_da15);
    $setuphold (posedge CLK &&& WEA, negedge DA[15], tdas, tdah, valid_da15);
    $setuphold (posedge CLK &&& WEB, posedge DB[15], tdbs, tdbh, valid_db15);
    $setuphold (posedge CLK &&& WEB, negedge DB[15], tdbs, tdbh, valid_db15);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[15], tbwas, tbwah, valid_bwa15);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[15], tbwas, tbwah, valid_bwa15);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[15], tbwbs, tbwbh, valid_bwb15);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[15], tbwbs, tbwbh, valid_bwb15);
    $setuphold (posedge CLK &&& WEA, posedge DA[16], tdas, tdah, valid_da16);
    $setuphold (posedge CLK &&& WEA, negedge DA[16], tdas, tdah, valid_da16);
    $setuphold (posedge CLK &&& WEB, posedge DB[16], tdbs, tdbh, valid_db16);
    $setuphold (posedge CLK &&& WEB, negedge DB[16], tdbs, tdbh, valid_db16);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[16], tbwas, tbwah, valid_bwa16);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[16], tbwas, tbwah, valid_bwa16);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[16], tbwbs, tbwbh, valid_bwb16);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[16], tbwbs, tbwbh, valid_bwb16);
    $setuphold (posedge CLK &&& WEA, posedge DA[17], tdas, tdah, valid_da17);
    $setuphold (posedge CLK &&& WEA, negedge DA[17], tdas, tdah, valid_da17);
    $setuphold (posedge CLK &&& WEB, posedge DB[17], tdbs, tdbh, valid_db17);
    $setuphold (posedge CLK &&& WEB, negedge DB[17], tdbs, tdbh, valid_db17);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[17], tbwas, tbwah, valid_bwa17);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[17], tbwas, tbwah, valid_bwa17);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[17], tbwbs, tbwbh, valid_bwb17);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[17], tbwbs, tbwbh, valid_bwb17);
    $setuphold (posedge CLK &&& WEA, posedge DA[18], tdas, tdah, valid_da18);
    $setuphold (posedge CLK &&& WEA, negedge DA[18], tdas, tdah, valid_da18);
    $setuphold (posedge CLK &&& WEB, posedge DB[18], tdbs, tdbh, valid_db18);
    $setuphold (posedge CLK &&& WEB, negedge DB[18], tdbs, tdbh, valid_db18);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[18], tbwas, tbwah, valid_bwa18);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[18], tbwas, tbwah, valid_bwa18);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[18], tbwbs, tbwbh, valid_bwb18);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[18], tbwbs, tbwbh, valid_bwb18);
    $setuphold (posedge CLK &&& WEA, posedge DA[19], tdas, tdah, valid_da19);
    $setuphold (posedge CLK &&& WEA, negedge DA[19], tdas, tdah, valid_da19);
    $setuphold (posedge CLK &&& WEB, posedge DB[19], tdbs, tdbh, valid_db19);
    $setuphold (posedge CLK &&& WEB, negedge DB[19], tdbs, tdbh, valid_db19);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[19], tbwas, tbwah, valid_bwa19);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[19], tbwas, tbwah, valid_bwa19);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[19], tbwbs, tbwbh, valid_bwb19);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[19], tbwbs, tbwbh, valid_bwb19);
    $setuphold (posedge CLK &&& WEA, posedge DA[20], tdas, tdah, valid_da20);
    $setuphold (posedge CLK &&& WEA, negedge DA[20], tdas, tdah, valid_da20);
    $setuphold (posedge CLK &&& WEB, posedge DB[20], tdbs, tdbh, valid_db20);
    $setuphold (posedge CLK &&& WEB, negedge DB[20], tdbs, tdbh, valid_db20);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[20], tbwas, tbwah, valid_bwa20);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[20], tbwas, tbwah, valid_bwa20);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[20], tbwbs, tbwbh, valid_bwb20);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[20], tbwbs, tbwbh, valid_bwb20);
    $setuphold (posedge CLK &&& WEA, posedge DA[21], tdas, tdah, valid_da21);
    $setuphold (posedge CLK &&& WEA, negedge DA[21], tdas, tdah, valid_da21);
    $setuphold (posedge CLK &&& WEB, posedge DB[21], tdbs, tdbh, valid_db21);
    $setuphold (posedge CLK &&& WEB, negedge DB[21], tdbs, tdbh, valid_db21);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[21], tbwas, tbwah, valid_bwa21);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[21], tbwas, tbwah, valid_bwa21);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[21], tbwbs, tbwbh, valid_bwb21);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[21], tbwbs, tbwbh, valid_bwb21);
    $setuphold (posedge CLK &&& WEA, posedge DA[22], tdas, tdah, valid_da22);
    $setuphold (posedge CLK &&& WEA, negedge DA[22], tdas, tdah, valid_da22);
    $setuphold (posedge CLK &&& WEB, posedge DB[22], tdbs, tdbh, valid_db22);
    $setuphold (posedge CLK &&& WEB, negedge DB[22], tdbs, tdbh, valid_db22);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[22], tbwas, tbwah, valid_bwa22);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[22], tbwas, tbwah, valid_bwa22);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[22], tbwbs, tbwbh, valid_bwb22);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[22], tbwbs, tbwbh, valid_bwb22);
    $setuphold (posedge CLK &&& WEA, posedge DA[23], tdas, tdah, valid_da23);
    $setuphold (posedge CLK &&& WEA, negedge DA[23], tdas, tdah, valid_da23);
    $setuphold (posedge CLK &&& WEB, posedge DB[23], tdbs, tdbh, valid_db23);
    $setuphold (posedge CLK &&& WEB, negedge DB[23], tdbs, tdbh, valid_db23);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[23], tbwas, tbwah, valid_bwa23);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[23], tbwas, tbwah, valid_bwa23);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[23], tbwbs, tbwbh, valid_bwb23);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[23], tbwbs, tbwbh, valid_bwb23);
    $setuphold (posedge CLK &&& WEA, posedge DA[24], tdas, tdah, valid_da24);
    $setuphold (posedge CLK &&& WEA, negedge DA[24], tdas, tdah, valid_da24);
    $setuphold (posedge CLK &&& WEB, posedge DB[24], tdbs, tdbh, valid_db24);
    $setuphold (posedge CLK &&& WEB, negedge DB[24], tdbs, tdbh, valid_db24);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[24], tbwas, tbwah, valid_bwa24);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[24], tbwas, tbwah, valid_bwa24);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[24], tbwbs, tbwbh, valid_bwb24);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[24], tbwbs, tbwbh, valid_bwb24);
    $setuphold (posedge CLK &&& WEA, posedge DA[25], tdas, tdah, valid_da25);
    $setuphold (posedge CLK &&& WEA, negedge DA[25], tdas, tdah, valid_da25);
    $setuphold (posedge CLK &&& WEB, posedge DB[25], tdbs, tdbh, valid_db25);
    $setuphold (posedge CLK &&& WEB, negedge DB[25], tdbs, tdbh, valid_db25);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[25], tbwas, tbwah, valid_bwa25);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[25], tbwas, tbwah, valid_bwa25);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[25], tbwbs, tbwbh, valid_bwb25);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[25], tbwbs, tbwbh, valid_bwb25);
    $setuphold (posedge CLK &&& WEA, posedge DA[26], tdas, tdah, valid_da26);
    $setuphold (posedge CLK &&& WEA, negedge DA[26], tdas, tdah, valid_da26);
    $setuphold (posedge CLK &&& WEB, posedge DB[26], tdbs, tdbh, valid_db26);
    $setuphold (posedge CLK &&& WEB, negedge DB[26], tdbs, tdbh, valid_db26);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[26], tbwas, tbwah, valid_bwa26);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[26], tbwas, tbwah, valid_bwa26);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[26], tbwbs, tbwbh, valid_bwb26);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[26], tbwbs, tbwbh, valid_bwb26);
    $setuphold (posedge CLK &&& WEA, posedge DA[27], tdas, tdah, valid_da27);
    $setuphold (posedge CLK &&& WEA, negedge DA[27], tdas, tdah, valid_da27);
    $setuphold (posedge CLK &&& WEB, posedge DB[27], tdbs, tdbh, valid_db27);
    $setuphold (posedge CLK &&& WEB, negedge DB[27], tdbs, tdbh, valid_db27);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[27], tbwas, tbwah, valid_bwa27);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[27], tbwas, tbwah, valid_bwa27);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[27], tbwbs, tbwbh, valid_bwb27);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[27], tbwbs, tbwbh, valid_bwb27);
    $setuphold (posedge CLK &&& WEA, posedge DA[28], tdas, tdah, valid_da28);
    $setuphold (posedge CLK &&& WEA, negedge DA[28], tdas, tdah, valid_da28);
    $setuphold (posedge CLK &&& WEB, posedge DB[28], tdbs, tdbh, valid_db28);
    $setuphold (posedge CLK &&& WEB, negedge DB[28], tdbs, tdbh, valid_db28);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[28], tbwas, tbwah, valid_bwa28);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[28], tbwas, tbwah, valid_bwa28);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[28], tbwbs, tbwbh, valid_bwb28);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[28], tbwbs, tbwbh, valid_bwb28);
    $setuphold (posedge CLK &&& WEA, posedge DA[29], tdas, tdah, valid_da29);
    $setuphold (posedge CLK &&& WEA, negedge DA[29], tdas, tdah, valid_da29);
    $setuphold (posedge CLK &&& WEB, posedge DB[29], tdbs, tdbh, valid_db29);
    $setuphold (posedge CLK &&& WEB, negedge DB[29], tdbs, tdbh, valid_db29);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[29], tbwas, tbwah, valid_bwa29);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[29], tbwas, tbwah, valid_bwa29);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[29], tbwbs, tbwbh, valid_bwb29);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[29], tbwbs, tbwbh, valid_bwb29);
    $setuphold (posedge CLK &&& WEA, posedge DA[30], tdas, tdah, valid_da30);
    $setuphold (posedge CLK &&& WEA, negedge DA[30], tdas, tdah, valid_da30);
    $setuphold (posedge CLK &&& WEB, posedge DB[30], tdbs, tdbh, valid_db30);
    $setuphold (posedge CLK &&& WEB, negedge DB[30], tdbs, tdbh, valid_db30);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[30], tbwas, tbwah, valid_bwa30);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[30], tbwas, tbwah, valid_bwa30);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[30], tbwbs, tbwbh, valid_bwb30);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[30], tbwbs, tbwbh, valid_bwb30);
    $setuphold (posedge CLK &&& WEA, posedge DA[31], tdas, tdah, valid_da31);
    $setuphold (posedge CLK &&& WEA, negedge DA[31], tdas, tdah, valid_da31);
    $setuphold (posedge CLK &&& WEB, posedge DB[31], tdbs, tdbh, valid_db31);
    $setuphold (posedge CLK &&& WEB, negedge DB[31], tdbs, tdbh, valid_db31);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[31], tbwas, tbwah, valid_bwa31);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[31], tbwas, tbwah, valid_bwa31);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[31], tbwbs, tbwbh, valid_bwb31);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[31], tbwbs, tbwbh, valid_bwb31);
    $setuphold (posedge CLK &&& WEA, posedge DA[32], tdas, tdah, valid_da32);
    $setuphold (posedge CLK &&& WEA, negedge DA[32], tdas, tdah, valid_da32);
    $setuphold (posedge CLK &&& WEB, posedge DB[32], tdbs, tdbh, valid_db32);
    $setuphold (posedge CLK &&& WEB, negedge DB[32], tdbs, tdbh, valid_db32);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[32], tbwas, tbwah, valid_bwa32);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[32], tbwas, tbwah, valid_bwa32);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[32], tbwbs, tbwbh, valid_bwb32);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[32], tbwbs, tbwbh, valid_bwb32);
    $setuphold (posedge CLK &&& WEA, posedge DA[33], tdas, tdah, valid_da33);
    $setuphold (posedge CLK &&& WEA, negedge DA[33], tdas, tdah, valid_da33);
    $setuphold (posedge CLK &&& WEB, posedge DB[33], tdbs, tdbh, valid_db33);
    $setuphold (posedge CLK &&& WEB, negedge DB[33], tdbs, tdbh, valid_db33);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[33], tbwas, tbwah, valid_bwa33);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[33], tbwas, tbwah, valid_bwa33);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[33], tbwbs, tbwbh, valid_bwb33);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[33], tbwbs, tbwbh, valid_bwb33);
    $setuphold (posedge CLK &&& WEA, posedge DA[34], tdas, tdah, valid_da34);
    $setuphold (posedge CLK &&& WEA, negedge DA[34], tdas, tdah, valid_da34);
    $setuphold (posedge CLK &&& WEB, posedge DB[34], tdbs, tdbh, valid_db34);
    $setuphold (posedge CLK &&& WEB, negedge DB[34], tdbs, tdbh, valid_db34);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[34], tbwas, tbwah, valid_bwa34);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[34], tbwas, tbwah, valid_bwa34);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[34], tbwbs, tbwbh, valid_bwb34);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[34], tbwbs, tbwbh, valid_bwb34);
    $setuphold (posedge CLK &&& WEA, posedge DA[35], tdas, tdah, valid_da35);
    $setuphold (posedge CLK &&& WEA, negedge DA[35], tdas, tdah, valid_da35);
    $setuphold (posedge CLK &&& WEB, posedge DB[35], tdbs, tdbh, valid_db35);
    $setuphold (posedge CLK &&& WEB, negedge DB[35], tdbs, tdbh, valid_db35);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[35], tbwas, tbwah, valid_bwa35);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[35], tbwas, tbwah, valid_bwa35);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[35], tbwbs, tbwbh, valid_bwb35);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[35], tbwbs, tbwbh, valid_bwb35);
    $setuphold (posedge CLK &&& WEA, posedge DA[36], tdas, tdah, valid_da36);
    $setuphold (posedge CLK &&& WEA, negedge DA[36], tdas, tdah, valid_da36);
    $setuphold (posedge CLK &&& WEB, posedge DB[36], tdbs, tdbh, valid_db36);
    $setuphold (posedge CLK &&& WEB, negedge DB[36], tdbs, tdbh, valid_db36);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[36], tbwas, tbwah, valid_bwa36);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[36], tbwas, tbwah, valid_bwa36);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[36], tbwbs, tbwbh, valid_bwb36);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[36], tbwbs, tbwbh, valid_bwb36);
    $setuphold (posedge CLK &&& WEA, posedge DA[37], tdas, tdah, valid_da37);
    $setuphold (posedge CLK &&& WEA, negedge DA[37], tdas, tdah, valid_da37);
    $setuphold (posedge CLK &&& WEB, posedge DB[37], tdbs, tdbh, valid_db37);
    $setuphold (posedge CLK &&& WEB, negedge DB[37], tdbs, tdbh, valid_db37);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[37], tbwas, tbwah, valid_bwa37);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[37], tbwas, tbwah, valid_bwa37);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[37], tbwbs, tbwbh, valid_bwb37);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[37], tbwbs, tbwbh, valid_bwb37);
    $setuphold (posedge CLK &&& WEA, posedge DA[38], tdas, tdah, valid_da38);
    $setuphold (posedge CLK &&& WEA, negedge DA[38], tdas, tdah, valid_da38);
    $setuphold (posedge CLK &&& WEB, posedge DB[38], tdbs, tdbh, valid_db38);
    $setuphold (posedge CLK &&& WEB, negedge DB[38], tdbs, tdbh, valid_db38);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[38], tbwas, tbwah, valid_bwa38);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[38], tbwas, tbwah, valid_bwa38);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[38], tbwbs, tbwbh, valid_bwb38);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[38], tbwbs, tbwbh, valid_bwb38);
    $setuphold (posedge CLK &&& WEA, posedge DA[39], tdas, tdah, valid_da39);
    $setuphold (posedge CLK &&& WEA, negedge DA[39], tdas, tdah, valid_da39);
    $setuphold (posedge CLK &&& WEB, posedge DB[39], tdbs, tdbh, valid_db39);
    $setuphold (posedge CLK &&& WEB, negedge DB[39], tdbs, tdbh, valid_db39);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[39], tbwas, tbwah, valid_bwa39);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[39], tbwas, tbwah, valid_bwa39);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[39], tbwbs, tbwbh, valid_bwb39);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[39], tbwbs, tbwbh, valid_bwb39);
    $setuphold (posedge CLK &&& WEA, posedge DA[40], tdas, tdah, valid_da40);
    $setuphold (posedge CLK &&& WEA, negedge DA[40], tdas, tdah, valid_da40);
    $setuphold (posedge CLK &&& WEB, posedge DB[40], tdbs, tdbh, valid_db40);
    $setuphold (posedge CLK &&& WEB, negedge DB[40], tdbs, tdbh, valid_db40);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[40], tbwas, tbwah, valid_bwa40);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[40], tbwas, tbwah, valid_bwa40);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[40], tbwbs, tbwbh, valid_bwb40);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[40], tbwbs, tbwbh, valid_bwb40);
    $setuphold (posedge CLK &&& WEA, posedge DA[41], tdas, tdah, valid_da41);
    $setuphold (posedge CLK &&& WEA, negedge DA[41], tdas, tdah, valid_da41);
    $setuphold (posedge CLK &&& WEB, posedge DB[41], tdbs, tdbh, valid_db41);
    $setuphold (posedge CLK &&& WEB, negedge DB[41], tdbs, tdbh, valid_db41);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[41], tbwas, tbwah, valid_bwa41);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[41], tbwas, tbwah, valid_bwa41);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[41], tbwbs, tbwbh, valid_bwb41);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[41], tbwbs, tbwbh, valid_bwb41);
    $setuphold (posedge CLK &&& WEA, posedge DA[42], tdas, tdah, valid_da42);
    $setuphold (posedge CLK &&& WEA, negedge DA[42], tdas, tdah, valid_da42);
    $setuphold (posedge CLK &&& WEB, posedge DB[42], tdbs, tdbh, valid_db42);
    $setuphold (posedge CLK &&& WEB, negedge DB[42], tdbs, tdbh, valid_db42);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[42], tbwas, tbwah, valid_bwa42);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[42], tbwas, tbwah, valid_bwa42);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[42], tbwbs, tbwbh, valid_bwb42);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[42], tbwbs, tbwbh, valid_bwb42);
    $setuphold (posedge CLK &&& WEA, posedge DA[43], tdas, tdah, valid_da43);
    $setuphold (posedge CLK &&& WEA, negedge DA[43], tdas, tdah, valid_da43);
    $setuphold (posedge CLK &&& WEB, posedge DB[43], tdbs, tdbh, valid_db43);
    $setuphold (posedge CLK &&& WEB, negedge DB[43], tdbs, tdbh, valid_db43);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[43], tbwas, tbwah, valid_bwa43);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[43], tbwas, tbwah, valid_bwa43);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[43], tbwbs, tbwbh, valid_bwb43);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[43], tbwbs, tbwbh, valid_bwb43);
    $setuphold (posedge CLK &&& WEA, posedge DA[44], tdas, tdah, valid_da44);
    $setuphold (posedge CLK &&& WEA, negedge DA[44], tdas, tdah, valid_da44);
    $setuphold (posedge CLK &&& WEB, posedge DB[44], tdbs, tdbh, valid_db44);
    $setuphold (posedge CLK &&& WEB, negedge DB[44], tdbs, tdbh, valid_db44);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[44], tbwas, tbwah, valid_bwa44);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[44], tbwas, tbwah, valid_bwa44);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[44], tbwbs, tbwbh, valid_bwb44);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[44], tbwbs, tbwbh, valid_bwb44);
    $setuphold (posedge CLK &&& WEA, posedge DA[45], tdas, tdah, valid_da45);
    $setuphold (posedge CLK &&& WEA, negedge DA[45], tdas, tdah, valid_da45);
    $setuphold (posedge CLK &&& WEB, posedge DB[45], tdbs, tdbh, valid_db45);
    $setuphold (posedge CLK &&& WEB, negedge DB[45], tdbs, tdbh, valid_db45);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[45], tbwas, tbwah, valid_bwa45);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[45], tbwas, tbwah, valid_bwa45);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[45], tbwbs, tbwbh, valid_bwb45);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[45], tbwbs, tbwbh, valid_bwb45);
    $setuphold (posedge CLK &&& WEA, posedge DA[46], tdas, tdah, valid_da46);
    $setuphold (posedge CLK &&& WEA, negedge DA[46], tdas, tdah, valid_da46);
    $setuphold (posedge CLK &&& WEB, posedge DB[46], tdbs, tdbh, valid_db46);
    $setuphold (posedge CLK &&& WEB, negedge DB[46], tdbs, tdbh, valid_db46);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[46], tbwas, tbwah, valid_bwa46);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[46], tbwas, tbwah, valid_bwa46);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[46], tbwbs, tbwbh, valid_bwb46);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[46], tbwbs, tbwbh, valid_bwb46);
    $setuphold (posedge CLK &&& WEA, posedge DA[47], tdas, tdah, valid_da47);
    $setuphold (posedge CLK &&& WEA, negedge DA[47], tdas, tdah, valid_da47);
    $setuphold (posedge CLK &&& WEB, posedge DB[47], tdbs, tdbh, valid_db47);
    $setuphold (posedge CLK &&& WEB, negedge DB[47], tdbs, tdbh, valid_db47);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[47], tbwas, tbwah, valid_bwa47);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[47], tbwas, tbwah, valid_bwa47);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[47], tbwbs, tbwbh, valid_bwb47);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[47], tbwbs, tbwbh, valid_bwb47);
    $setuphold (posedge CLK &&& WEA, posedge DA[48], tdas, tdah, valid_da48);
    $setuphold (posedge CLK &&& WEA, negedge DA[48], tdas, tdah, valid_da48);
    $setuphold (posedge CLK &&& WEB, posedge DB[48], tdbs, tdbh, valid_db48);
    $setuphold (posedge CLK &&& WEB, negedge DB[48], tdbs, tdbh, valid_db48);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[48], tbwas, tbwah, valid_bwa48);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[48], tbwas, tbwah, valid_bwa48);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[48], tbwbs, tbwbh, valid_bwb48);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[48], tbwbs, tbwbh, valid_bwb48);
    $setuphold (posedge CLK &&& WEA, posedge DA[49], tdas, tdah, valid_da49);
    $setuphold (posedge CLK &&& WEA, negedge DA[49], tdas, tdah, valid_da49);
    $setuphold (posedge CLK &&& WEB, posedge DB[49], tdbs, tdbh, valid_db49);
    $setuphold (posedge CLK &&& WEB, negedge DB[49], tdbs, tdbh, valid_db49);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[49], tbwas, tbwah, valid_bwa49);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[49], tbwas, tbwah, valid_bwa49);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[49], tbwbs, tbwbh, valid_bwb49);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[49], tbwbs, tbwbh, valid_bwb49);
    $setuphold (posedge CLK &&& WEA, posedge DA[50], tdas, tdah, valid_da50);
    $setuphold (posedge CLK &&& WEA, negedge DA[50], tdas, tdah, valid_da50);
    $setuphold (posedge CLK &&& WEB, posedge DB[50], tdbs, tdbh, valid_db50);
    $setuphold (posedge CLK &&& WEB, negedge DB[50], tdbs, tdbh, valid_db50);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[50], tbwas, tbwah, valid_bwa50);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[50], tbwas, tbwah, valid_bwa50);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[50], tbwbs, tbwbh, valid_bwb50);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[50], tbwbs, tbwbh, valid_bwb50);
    $setuphold (posedge CLK &&& WEA, posedge DA[51], tdas, tdah, valid_da51);
    $setuphold (posedge CLK &&& WEA, negedge DA[51], tdas, tdah, valid_da51);
    $setuphold (posedge CLK &&& WEB, posedge DB[51], tdbs, tdbh, valid_db51);
    $setuphold (posedge CLK &&& WEB, negedge DB[51], tdbs, tdbh, valid_db51);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[51], tbwas, tbwah, valid_bwa51);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[51], tbwas, tbwah, valid_bwa51);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[51], tbwbs, tbwbh, valid_bwb51);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[51], tbwbs, tbwbh, valid_bwb51);
    $setuphold (posedge CLK &&& WEA, posedge DA[52], tdas, tdah, valid_da52);
    $setuphold (posedge CLK &&& WEA, negedge DA[52], tdas, tdah, valid_da52);
    $setuphold (posedge CLK &&& WEB, posedge DB[52], tdbs, tdbh, valid_db52);
    $setuphold (posedge CLK &&& WEB, negedge DB[52], tdbs, tdbh, valid_db52);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[52], tbwas, tbwah, valid_bwa52);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[52], tbwas, tbwah, valid_bwa52);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[52], tbwbs, tbwbh, valid_bwb52);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[52], tbwbs, tbwbh, valid_bwb52);
    $setuphold (posedge CLK &&& WEA, posedge DA[53], tdas, tdah, valid_da53);
    $setuphold (posedge CLK &&& WEA, negedge DA[53], tdas, tdah, valid_da53);
    $setuphold (posedge CLK &&& WEB, posedge DB[53], tdbs, tdbh, valid_db53);
    $setuphold (posedge CLK &&& WEB, negedge DB[53], tdbs, tdbh, valid_db53);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[53], tbwas, tbwah, valid_bwa53);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[53], tbwas, tbwah, valid_bwa53);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[53], tbwbs, tbwbh, valid_bwb53);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[53], tbwbs, tbwbh, valid_bwb53);
    $setuphold (posedge CLK &&& WEA, posedge DA[54], tdas, tdah, valid_da54);
    $setuphold (posedge CLK &&& WEA, negedge DA[54], tdas, tdah, valid_da54);
    $setuphold (posedge CLK &&& WEB, posedge DB[54], tdbs, tdbh, valid_db54);
    $setuphold (posedge CLK &&& WEB, negedge DB[54], tdbs, tdbh, valid_db54);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[54], tbwas, tbwah, valid_bwa54);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[54], tbwas, tbwah, valid_bwa54);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[54], tbwbs, tbwbh, valid_bwb54);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[54], tbwbs, tbwbh, valid_bwb54);
    $setuphold (posedge CLK &&& WEA, posedge DA[55], tdas, tdah, valid_da55);
    $setuphold (posedge CLK &&& WEA, negedge DA[55], tdas, tdah, valid_da55);
    $setuphold (posedge CLK &&& WEB, posedge DB[55], tdbs, tdbh, valid_db55);
    $setuphold (posedge CLK &&& WEB, negedge DB[55], tdbs, tdbh, valid_db55);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[55], tbwas, tbwah, valid_bwa55);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[55], tbwas, tbwah, valid_bwa55);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[55], tbwbs, tbwbh, valid_bwb55);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[55], tbwbs, tbwbh, valid_bwb55);
    $setuphold (posedge CLK &&& WEA, posedge DA[56], tdas, tdah, valid_da56);
    $setuphold (posedge CLK &&& WEA, negedge DA[56], tdas, tdah, valid_da56);
    $setuphold (posedge CLK &&& WEB, posedge DB[56], tdbs, tdbh, valid_db56);
    $setuphold (posedge CLK &&& WEB, negedge DB[56], tdbs, tdbh, valid_db56);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[56], tbwas, tbwah, valid_bwa56);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[56], tbwas, tbwah, valid_bwa56);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[56], tbwbs, tbwbh, valid_bwb56);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[56], tbwbs, tbwbh, valid_bwb56);
    $setuphold (posedge CLK &&& WEA, posedge DA[57], tdas, tdah, valid_da57);
    $setuphold (posedge CLK &&& WEA, negedge DA[57], tdas, tdah, valid_da57);
    $setuphold (posedge CLK &&& WEB, posedge DB[57], tdbs, tdbh, valid_db57);
    $setuphold (posedge CLK &&& WEB, negedge DB[57], tdbs, tdbh, valid_db57);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[57], tbwas, tbwah, valid_bwa57);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[57], tbwas, tbwah, valid_bwa57);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[57], tbwbs, tbwbh, valid_bwb57);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[57], tbwbs, tbwbh, valid_bwb57);
    $setuphold (posedge CLK &&& WEA, posedge DA[58], tdas, tdah, valid_da58);
    $setuphold (posedge CLK &&& WEA, negedge DA[58], tdas, tdah, valid_da58);
    $setuphold (posedge CLK &&& WEB, posedge DB[58], tdbs, tdbh, valid_db58);
    $setuphold (posedge CLK &&& WEB, negedge DB[58], tdbs, tdbh, valid_db58);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[58], tbwas, tbwah, valid_bwa58);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[58], tbwas, tbwah, valid_bwa58);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[58], tbwbs, tbwbh, valid_bwb58);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[58], tbwbs, tbwbh, valid_bwb58);
    $setuphold (posedge CLK &&& WEA, posedge DA[59], tdas, tdah, valid_da59);
    $setuphold (posedge CLK &&& WEA, negedge DA[59], tdas, tdah, valid_da59);
    $setuphold (posedge CLK &&& WEB, posedge DB[59], tdbs, tdbh, valid_db59);
    $setuphold (posedge CLK &&& WEB, negedge DB[59], tdbs, tdbh, valid_db59);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[59], tbwas, tbwah, valid_bwa59);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[59], tbwas, tbwah, valid_bwa59);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[59], tbwbs, tbwbh, valid_bwb59);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[59], tbwbs, tbwbh, valid_bwb59);
    $setuphold (posedge CLK &&& WEA, posedge DA[60], tdas, tdah, valid_da60);
    $setuphold (posedge CLK &&& WEA, negedge DA[60], tdas, tdah, valid_da60);
    $setuphold (posedge CLK &&& WEB, posedge DB[60], tdbs, tdbh, valid_db60);
    $setuphold (posedge CLK &&& WEB, negedge DB[60], tdbs, tdbh, valid_db60);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[60], tbwas, tbwah, valid_bwa60);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[60], tbwas, tbwah, valid_bwa60);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[60], tbwbs, tbwbh, valid_bwb60);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[60], tbwbs, tbwbh, valid_bwb60);
    $setuphold (posedge CLK &&& WEA, posedge DA[61], tdas, tdah, valid_da61);
    $setuphold (posedge CLK &&& WEA, negedge DA[61], tdas, tdah, valid_da61);
    $setuphold (posedge CLK &&& WEB, posedge DB[61], tdbs, tdbh, valid_db61);
    $setuphold (posedge CLK &&& WEB, negedge DB[61], tdbs, tdbh, valid_db61);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[61], tbwas, tbwah, valid_bwa61);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[61], tbwas, tbwah, valid_bwa61);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[61], tbwbs, tbwbh, valid_bwb61);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[61], tbwbs, tbwbh, valid_bwb61);
    $setuphold (posedge CLK &&& WEA, posedge DA[62], tdas, tdah, valid_da62);
    $setuphold (posedge CLK &&& WEA, negedge DA[62], tdas, tdah, valid_da62);
    $setuphold (posedge CLK &&& WEB, posedge DB[62], tdbs, tdbh, valid_db62);
    $setuphold (posedge CLK &&& WEB, negedge DB[62], tdbs, tdbh, valid_db62);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[62], tbwas, tbwah, valid_bwa62);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[62], tbwas, tbwah, valid_bwa62);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[62], tbwbs, tbwbh, valid_bwb62);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[62], tbwbs, tbwbh, valid_bwb62);
    $setuphold (posedge CLK &&& WEA, posedge DA[63], tdas, tdah, valid_da63);
    $setuphold (posedge CLK &&& WEA, negedge DA[63], tdas, tdah, valid_da63);
    $setuphold (posedge CLK &&& WEB, posedge DB[63], tdbs, tdbh, valid_db63);
    $setuphold (posedge CLK &&& WEB, negedge DB[63], tdbs, tdbh, valid_db63);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[63], tbwas, tbwah, valid_bwa63);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[63], tbwas, tbwah, valid_bwa63);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[63], tbwbs, tbwbh, valid_bwb63);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[63], tbwbs, tbwbh, valid_bwb63);
    $setuphold (posedge CLK &&& WEA, posedge DA[64], tdas, tdah, valid_da64);
    $setuphold (posedge CLK &&& WEA, negedge DA[64], tdas, tdah, valid_da64);
    $setuphold (posedge CLK &&& WEB, posedge DB[64], tdbs, tdbh, valid_db64);
    $setuphold (posedge CLK &&& WEB, negedge DB[64], tdbs, tdbh, valid_db64);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[64], tbwas, tbwah, valid_bwa64);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[64], tbwas, tbwah, valid_bwa64);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[64], tbwbs, tbwbh, valid_bwb64);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[64], tbwbs, tbwbh, valid_bwb64);
    $setuphold (posedge CLK &&& WEA, posedge DA[65], tdas, tdah, valid_da65);
    $setuphold (posedge CLK &&& WEA, negedge DA[65], tdas, tdah, valid_da65);
    $setuphold (posedge CLK &&& WEB, posedge DB[65], tdbs, tdbh, valid_db65);
    $setuphold (posedge CLK &&& WEB, negedge DB[65], tdbs, tdbh, valid_db65);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[65], tbwas, tbwah, valid_bwa65);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[65], tbwas, tbwah, valid_bwa65);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[65], tbwbs, tbwbh, valid_bwb65);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[65], tbwbs, tbwbh, valid_bwb65);
    $setuphold (posedge CLK &&& WEA, posedge DA[66], tdas, tdah, valid_da66);
    $setuphold (posedge CLK &&& WEA, negedge DA[66], tdas, tdah, valid_da66);
    $setuphold (posedge CLK &&& WEB, posedge DB[66], tdbs, tdbh, valid_db66);
    $setuphold (posedge CLK &&& WEB, negedge DB[66], tdbs, tdbh, valid_db66);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[66], tbwas, tbwah, valid_bwa66);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[66], tbwas, tbwah, valid_bwa66);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[66], tbwbs, tbwbh, valid_bwb66);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[66], tbwbs, tbwbh, valid_bwb66);
    $setuphold (posedge CLK &&& WEA, posedge DA[67], tdas, tdah, valid_da67);
    $setuphold (posedge CLK &&& WEA, negedge DA[67], tdas, tdah, valid_da67);
    $setuphold (posedge CLK &&& WEB, posedge DB[67], tdbs, tdbh, valid_db67);
    $setuphold (posedge CLK &&& WEB, negedge DB[67], tdbs, tdbh, valid_db67);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[67], tbwas, tbwah, valid_bwa67);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[67], tbwas, tbwah, valid_bwa67);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[67], tbwbs, tbwbh, valid_bwb67);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[67], tbwbs, tbwbh, valid_bwb67);
    $setuphold (posedge CLK &&& WEA, posedge DA[68], tdas, tdah, valid_da68);
    $setuphold (posedge CLK &&& WEA, negedge DA[68], tdas, tdah, valid_da68);
    $setuphold (posedge CLK &&& WEB, posedge DB[68], tdbs, tdbh, valid_db68);
    $setuphold (posedge CLK &&& WEB, negedge DB[68], tdbs, tdbh, valid_db68);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[68], tbwas, tbwah, valid_bwa68);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[68], tbwas, tbwah, valid_bwa68);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[68], tbwbs, tbwbh, valid_bwb68);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[68], tbwbs, tbwbh, valid_bwb68);
    $setuphold (posedge CLK &&& WEA, posedge DA[69], tdas, tdah, valid_da69);
    $setuphold (posedge CLK &&& WEA, negedge DA[69], tdas, tdah, valid_da69);
    $setuphold (posedge CLK &&& WEB, posedge DB[69], tdbs, tdbh, valid_db69);
    $setuphold (posedge CLK &&& WEB, negedge DB[69], tdbs, tdbh, valid_db69);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[69], tbwas, tbwah, valid_bwa69);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[69], tbwas, tbwah, valid_bwa69);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[69], tbwbs, tbwbh, valid_bwb69);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[69], tbwbs, tbwbh, valid_bwb69);
    $setuphold (posedge CLK &&& WEA, posedge DA[70], tdas, tdah, valid_da70);
    $setuphold (posedge CLK &&& WEA, negedge DA[70], tdas, tdah, valid_da70);
    $setuphold (posedge CLK &&& WEB, posedge DB[70], tdbs, tdbh, valid_db70);
    $setuphold (posedge CLK &&& WEB, negedge DB[70], tdbs, tdbh, valid_db70);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[70], tbwas, tbwah, valid_bwa70);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[70], tbwas, tbwah, valid_bwa70);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[70], tbwbs, tbwbh, valid_bwb70);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[70], tbwbs, tbwbh, valid_bwb70);
    $setuphold (posedge CLK &&& WEA, posedge DA[71], tdas, tdah, valid_da71);
    $setuphold (posedge CLK &&& WEA, negedge DA[71], tdas, tdah, valid_da71);
    $setuphold (posedge CLK &&& WEB, posedge DB[71], tdbs, tdbh, valid_db71);
    $setuphold (posedge CLK &&& WEB, negedge DB[71], tdbs, tdbh, valid_db71);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[71], tbwas, tbwah, valid_bwa71);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[71], tbwas, tbwah, valid_bwa71);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[71], tbwbs, tbwbh, valid_bwb71);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[71], tbwbs, tbwbh, valid_bwb71);
    $setuphold (posedge CLK &&& WEA, posedge DA[72], tdas, tdah, valid_da72);
    $setuphold (posedge CLK &&& WEA, negedge DA[72], tdas, tdah, valid_da72);
    $setuphold (posedge CLK &&& WEB, posedge DB[72], tdbs, tdbh, valid_db72);
    $setuphold (posedge CLK &&& WEB, negedge DB[72], tdbs, tdbh, valid_db72);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[72], tbwas, tbwah, valid_bwa72);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[72], tbwas, tbwah, valid_bwa72);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[72], tbwbs, tbwbh, valid_bwb72);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[72], tbwbs, tbwbh, valid_bwb72);
    $setuphold (posedge CLK &&& WEA, posedge DA[73], tdas, tdah, valid_da73);
    $setuphold (posedge CLK &&& WEA, negedge DA[73], tdas, tdah, valid_da73);
    $setuphold (posedge CLK &&& WEB, posedge DB[73], tdbs, tdbh, valid_db73);
    $setuphold (posedge CLK &&& WEB, negedge DB[73], tdbs, tdbh, valid_db73);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[73], tbwas, tbwah, valid_bwa73);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[73], tbwas, tbwah, valid_bwa73);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[73], tbwbs, tbwbh, valid_bwb73);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[73], tbwbs, tbwbh, valid_bwb73);
    $setuphold (posedge CLK &&& WEA, posedge DA[74], tdas, tdah, valid_da74);
    $setuphold (posedge CLK &&& WEA, negedge DA[74], tdas, tdah, valid_da74);
    $setuphold (posedge CLK &&& WEB, posedge DB[74], tdbs, tdbh, valid_db74);
    $setuphold (posedge CLK &&& WEB, negedge DB[74], tdbs, tdbh, valid_db74);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[74], tbwas, tbwah, valid_bwa74);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[74], tbwas, tbwah, valid_bwa74);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[74], tbwbs, tbwbh, valid_bwb74);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[74], tbwbs, tbwbh, valid_bwb74);
    $setuphold (posedge CLK &&& WEA, posedge DA[75], tdas, tdah, valid_da75);
    $setuphold (posedge CLK &&& WEA, negedge DA[75], tdas, tdah, valid_da75);
    $setuphold (posedge CLK &&& WEB, posedge DB[75], tdbs, tdbh, valid_db75);
    $setuphold (posedge CLK &&& WEB, negedge DB[75], tdbs, tdbh, valid_db75);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[75], tbwas, tbwah, valid_bwa75);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[75], tbwas, tbwah, valid_bwa75);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[75], tbwbs, tbwbh, valid_bwb75);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[75], tbwbs, tbwbh, valid_bwb75);
    $setuphold (posedge CLK &&& WEA, posedge DA[76], tdas, tdah, valid_da76);
    $setuphold (posedge CLK &&& WEA, negedge DA[76], tdas, tdah, valid_da76);
    $setuphold (posedge CLK &&& WEB, posedge DB[76], tdbs, tdbh, valid_db76);
    $setuphold (posedge CLK &&& WEB, negedge DB[76], tdbs, tdbh, valid_db76);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[76], tbwas, tbwah, valid_bwa76);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[76], tbwas, tbwah, valid_bwa76);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[76], tbwbs, tbwbh, valid_bwb76);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[76], tbwbs, tbwbh, valid_bwb76);
    $setuphold (posedge CLK &&& WEA, posedge DA[77], tdas, tdah, valid_da77);
    $setuphold (posedge CLK &&& WEA, negedge DA[77], tdas, tdah, valid_da77);
    $setuphold (posedge CLK &&& WEB, posedge DB[77], tdbs, tdbh, valid_db77);
    $setuphold (posedge CLK &&& WEB, negedge DB[77], tdbs, tdbh, valid_db77);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[77], tbwas, tbwah, valid_bwa77);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[77], tbwas, tbwah, valid_bwa77);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[77], tbwbs, tbwbh, valid_bwb77);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[77], tbwbs, tbwbh, valid_bwb77);
    $setuphold (posedge CLK &&& WEA, posedge DA[78], tdas, tdah, valid_da78);
    $setuphold (posedge CLK &&& WEA, negedge DA[78], tdas, tdah, valid_da78);
    $setuphold (posedge CLK &&& WEB, posedge DB[78], tdbs, tdbh, valid_db78);
    $setuphold (posedge CLK &&& WEB, negedge DB[78], tdbs, tdbh, valid_db78);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[78], tbwas, tbwah, valid_bwa78);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[78], tbwas, tbwah, valid_bwa78);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[78], tbwbs, tbwbh, valid_bwb78);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[78], tbwbs, tbwbh, valid_bwb78);
    $setuphold (posedge CLK &&& WEA, posedge DA[79], tdas, tdah, valid_da79);
    $setuphold (posedge CLK &&& WEA, negedge DA[79], tdas, tdah, valid_da79);
    $setuphold (posedge CLK &&& WEB, posedge DB[79], tdbs, tdbh, valid_db79);
    $setuphold (posedge CLK &&& WEB, negedge DB[79], tdbs, tdbh, valid_db79);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[79], tbwas, tbwah, valid_bwa79);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[79], tbwas, tbwah, valid_bwa79);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[79], tbwbs, tbwbh, valid_bwb79);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[79], tbwbs, tbwbh, valid_bwb79);
    $setuphold (posedge CLK &&& WEA, posedge DA[80], tdas, tdah, valid_da80);
    $setuphold (posedge CLK &&& WEA, negedge DA[80], tdas, tdah, valid_da80);
    $setuphold (posedge CLK &&& WEB, posedge DB[80], tdbs, tdbh, valid_db80);
    $setuphold (posedge CLK &&& WEB, negedge DB[80], tdbs, tdbh, valid_db80);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[80], tbwas, tbwah, valid_bwa80);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[80], tbwas, tbwah, valid_bwa80);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[80], tbwbs, tbwbh, valid_bwb80);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[80], tbwbs, tbwbh, valid_bwb80);
    $setuphold (posedge CLK &&& WEA, posedge DA[81], tdas, tdah, valid_da81);
    $setuphold (posedge CLK &&& WEA, negedge DA[81], tdas, tdah, valid_da81);
    $setuphold (posedge CLK &&& WEB, posedge DB[81], tdbs, tdbh, valid_db81);
    $setuphold (posedge CLK &&& WEB, negedge DB[81], tdbs, tdbh, valid_db81);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[81], tbwas, tbwah, valid_bwa81);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[81], tbwas, tbwah, valid_bwa81);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[81], tbwbs, tbwbh, valid_bwb81);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[81], tbwbs, tbwbh, valid_bwb81);
    $setuphold (posedge CLK &&& WEA, posedge DA[82], tdas, tdah, valid_da82);
    $setuphold (posedge CLK &&& WEA, negedge DA[82], tdas, tdah, valid_da82);
    $setuphold (posedge CLK &&& WEB, posedge DB[82], tdbs, tdbh, valid_db82);
    $setuphold (posedge CLK &&& WEB, negedge DB[82], tdbs, tdbh, valid_db82);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[82], tbwas, tbwah, valid_bwa82);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[82], tbwas, tbwah, valid_bwa82);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[82], tbwbs, tbwbh, valid_bwb82);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[82], tbwbs, tbwbh, valid_bwb82);
    $setuphold (posedge CLK &&& WEA, posedge DA[83], tdas, tdah, valid_da83);
    $setuphold (posedge CLK &&& WEA, negedge DA[83], tdas, tdah, valid_da83);
    $setuphold (posedge CLK &&& WEB, posedge DB[83], tdbs, tdbh, valid_db83);
    $setuphold (posedge CLK &&& WEB, negedge DB[83], tdbs, tdbh, valid_db83);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[83], tbwas, tbwah, valid_bwa83);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[83], tbwas, tbwah, valid_bwa83);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[83], tbwbs, tbwbh, valid_bwb83);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[83], tbwbs, tbwbh, valid_bwb83);
    $setuphold (posedge CLK &&& WEA, posedge DA[84], tdas, tdah, valid_da84);
    $setuphold (posedge CLK &&& WEA, negedge DA[84], tdas, tdah, valid_da84);
    $setuphold (posedge CLK &&& WEB, posedge DB[84], tdbs, tdbh, valid_db84);
    $setuphold (posedge CLK &&& WEB, negedge DB[84], tdbs, tdbh, valid_db84);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[84], tbwas, tbwah, valid_bwa84);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[84], tbwas, tbwah, valid_bwa84);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[84], tbwbs, tbwbh, valid_bwb84);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[84], tbwbs, tbwbh, valid_bwb84);
    $setuphold (posedge CLK &&& WEA, posedge DA[85], tdas, tdah, valid_da85);
    $setuphold (posedge CLK &&& WEA, negedge DA[85], tdas, tdah, valid_da85);
    $setuphold (posedge CLK &&& WEB, posedge DB[85], tdbs, tdbh, valid_db85);
    $setuphold (posedge CLK &&& WEB, negedge DB[85], tdbs, tdbh, valid_db85);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[85], tbwas, tbwah, valid_bwa85);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[85], tbwas, tbwah, valid_bwa85);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[85], tbwbs, tbwbh, valid_bwb85);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[85], tbwbs, tbwbh, valid_bwb85);
    $setuphold (posedge CLK &&& WEA, posedge DA[86], tdas, tdah, valid_da86);
    $setuphold (posedge CLK &&& WEA, negedge DA[86], tdas, tdah, valid_da86);
    $setuphold (posedge CLK &&& WEB, posedge DB[86], tdbs, tdbh, valid_db86);
    $setuphold (posedge CLK &&& WEB, negedge DB[86], tdbs, tdbh, valid_db86);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[86], tbwas, tbwah, valid_bwa86);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[86], tbwas, tbwah, valid_bwa86);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[86], tbwbs, tbwbh, valid_bwb86);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[86], tbwbs, tbwbh, valid_bwb86);
    $setuphold (posedge CLK &&& WEA, posedge DA[87], tdas, tdah, valid_da87);
    $setuphold (posedge CLK &&& WEA, negedge DA[87], tdas, tdah, valid_da87);
    $setuphold (posedge CLK &&& WEB, posedge DB[87], tdbs, tdbh, valid_db87);
    $setuphold (posedge CLK &&& WEB, negedge DB[87], tdbs, tdbh, valid_db87);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[87], tbwas, tbwah, valid_bwa87);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[87], tbwas, tbwah, valid_bwa87);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[87], tbwbs, tbwbh, valid_bwb87);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[87], tbwbs, tbwbh, valid_bwb87);
    $setuphold (posedge CLK &&& WEA, posedge DA[88], tdas, tdah, valid_da88);
    $setuphold (posedge CLK &&& WEA, negedge DA[88], tdas, tdah, valid_da88);
    $setuphold (posedge CLK &&& WEB, posedge DB[88], tdbs, tdbh, valid_db88);
    $setuphold (posedge CLK &&& WEB, negedge DB[88], tdbs, tdbh, valid_db88);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[88], tbwas, tbwah, valid_bwa88);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[88], tbwas, tbwah, valid_bwa88);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[88], tbwbs, tbwbh, valid_bwb88);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[88], tbwbs, tbwbh, valid_bwb88);
    $setuphold (posedge CLK &&& WEA, posedge DA[89], tdas, tdah, valid_da89);
    $setuphold (posedge CLK &&& WEA, negedge DA[89], tdas, tdah, valid_da89);
    $setuphold (posedge CLK &&& WEB, posedge DB[89], tdbs, tdbh, valid_db89);
    $setuphold (posedge CLK &&& WEB, negedge DB[89], tdbs, tdbh, valid_db89);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[89], tbwas, tbwah, valid_bwa89);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[89], tbwas, tbwah, valid_bwa89);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[89], tbwbs, tbwbh, valid_bwb89);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[89], tbwbs, tbwbh, valid_bwb89);
    $setuphold (posedge CLK &&& WEA, posedge DA[90], tdas, tdah, valid_da90);
    $setuphold (posedge CLK &&& WEA, negedge DA[90], tdas, tdah, valid_da90);
    $setuphold (posedge CLK &&& WEB, posedge DB[90], tdbs, tdbh, valid_db90);
    $setuphold (posedge CLK &&& WEB, negedge DB[90], tdbs, tdbh, valid_db90);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[90], tbwas, tbwah, valid_bwa90);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[90], tbwas, tbwah, valid_bwa90);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[90], tbwbs, tbwbh, valid_bwb90);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[90], tbwbs, tbwbh, valid_bwb90);
    $setuphold (posedge CLK &&& WEA, posedge DA[91], tdas, tdah, valid_da91);
    $setuphold (posedge CLK &&& WEA, negedge DA[91], tdas, tdah, valid_da91);
    $setuphold (posedge CLK &&& WEB, posedge DB[91], tdbs, tdbh, valid_db91);
    $setuphold (posedge CLK &&& WEB, negedge DB[91], tdbs, tdbh, valid_db91);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[91], tbwas, tbwah, valid_bwa91);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[91], tbwas, tbwah, valid_bwa91);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[91], tbwbs, tbwbh, valid_bwb91);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[91], tbwbs, tbwbh, valid_bwb91);
    $setuphold (posedge CLK &&& WEA, posedge DA[92], tdas, tdah, valid_da92);
    $setuphold (posedge CLK &&& WEA, negedge DA[92], tdas, tdah, valid_da92);
    $setuphold (posedge CLK &&& WEB, posedge DB[92], tdbs, tdbh, valid_db92);
    $setuphold (posedge CLK &&& WEB, negedge DB[92], tdbs, tdbh, valid_db92);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[92], tbwas, tbwah, valid_bwa92);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[92], tbwas, tbwah, valid_bwa92);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[92], tbwbs, tbwbh, valid_bwb92);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[92], tbwbs, tbwbh, valid_bwb92);
    $setuphold (posedge CLK &&& WEA, posedge DA[93], tdas, tdah, valid_da93);
    $setuphold (posedge CLK &&& WEA, negedge DA[93], tdas, tdah, valid_da93);
    $setuphold (posedge CLK &&& WEB, posedge DB[93], tdbs, tdbh, valid_db93);
    $setuphold (posedge CLK &&& WEB, negedge DB[93], tdbs, tdbh, valid_db93);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[93], tbwas, tbwah, valid_bwa93);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[93], tbwas, tbwah, valid_bwa93);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[93], tbwbs, tbwbh, valid_bwb93);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[93], tbwbs, tbwbh, valid_bwb93);
    $setuphold (posedge CLK &&& WEA, posedge DA[94], tdas, tdah, valid_da94);
    $setuphold (posedge CLK &&& WEA, negedge DA[94], tdas, tdah, valid_da94);
    $setuphold (posedge CLK &&& WEB, posedge DB[94], tdbs, tdbh, valid_db94);
    $setuphold (posedge CLK &&& WEB, negedge DB[94], tdbs, tdbh, valid_db94);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[94], tbwas, tbwah, valid_bwa94);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[94], tbwas, tbwah, valid_bwa94);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[94], tbwbs, tbwbh, valid_bwb94);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[94], tbwbs, tbwbh, valid_bwb94);
    $setuphold (posedge CLK &&& WEA, posedge DA[95], tdas, tdah, valid_da95);
    $setuphold (posedge CLK &&& WEA, negedge DA[95], tdas, tdah, valid_da95);
    $setuphold (posedge CLK &&& WEB, posedge DB[95], tdbs, tdbh, valid_db95);
    $setuphold (posedge CLK &&& WEB, negedge DB[95], tdbs, tdbh, valid_db95);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[95], tbwas, tbwah, valid_bwa95);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[95], tbwas, tbwah, valid_bwa95);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[95], tbwbs, tbwbh, valid_bwb95);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[95], tbwbs, tbwbh, valid_bwb95);
    $setuphold (posedge CLK &&& WEA, posedge DA[96], tdas, tdah, valid_da96);
    $setuphold (posedge CLK &&& WEA, negedge DA[96], tdas, tdah, valid_da96);
    $setuphold (posedge CLK &&& WEB, posedge DB[96], tdbs, tdbh, valid_db96);
    $setuphold (posedge CLK &&& WEB, negedge DB[96], tdbs, tdbh, valid_db96);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[96], tbwas, tbwah, valid_bwa96);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[96], tbwas, tbwah, valid_bwa96);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[96], tbwbs, tbwbh, valid_bwb96);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[96], tbwbs, tbwbh, valid_bwb96);
    $setuphold (posedge CLK &&& WEA, posedge DA[97], tdas, tdah, valid_da97);
    $setuphold (posedge CLK &&& WEA, negedge DA[97], tdas, tdah, valid_da97);
    $setuphold (posedge CLK &&& WEB, posedge DB[97], tdbs, tdbh, valid_db97);
    $setuphold (posedge CLK &&& WEB, negedge DB[97], tdbs, tdbh, valid_db97);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[97], tbwas, tbwah, valid_bwa97);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[97], tbwas, tbwah, valid_bwa97);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[97], tbwbs, tbwbh, valid_bwb97);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[97], tbwbs, tbwbh, valid_bwb97);
    $setuphold (posedge CLK &&& WEA, posedge DA[98], tdas, tdah, valid_da98);
    $setuphold (posedge CLK &&& WEA, negedge DA[98], tdas, tdah, valid_da98);
    $setuphold (posedge CLK &&& WEB, posedge DB[98], tdbs, tdbh, valid_db98);
    $setuphold (posedge CLK &&& WEB, negedge DB[98], tdbs, tdbh, valid_db98);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[98], tbwas, tbwah, valid_bwa98);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[98], tbwas, tbwah, valid_bwa98);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[98], tbwbs, tbwbh, valid_bwb98);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[98], tbwbs, tbwbh, valid_bwb98);
    $setuphold (posedge CLK &&& WEA, posedge DA[99], tdas, tdah, valid_da99);
    $setuphold (posedge CLK &&& WEA, negedge DA[99], tdas, tdah, valid_da99);
    $setuphold (posedge CLK &&& WEB, posedge DB[99], tdbs, tdbh, valid_db99);
    $setuphold (posedge CLK &&& WEB, negedge DB[99], tdbs, tdbh, valid_db99);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[99], tbwas, tbwah, valid_bwa99);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[99], tbwas, tbwah, valid_bwa99);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[99], tbwbs, tbwbh, valid_bwb99);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[99], tbwbs, tbwbh, valid_bwb99);
    $setuphold (posedge CLK &&& WEA, posedge DA[100], tdas, tdah, valid_da100);
    $setuphold (posedge CLK &&& WEA, negedge DA[100], tdas, tdah, valid_da100);
    $setuphold (posedge CLK &&& WEB, posedge DB[100], tdbs, tdbh, valid_db100);
    $setuphold (posedge CLK &&& WEB, negedge DB[100], tdbs, tdbh, valid_db100);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[100], tbwas, tbwah, valid_bwa100);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[100], tbwas, tbwah, valid_bwa100);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[100], tbwbs, tbwbh, valid_bwb100);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[100], tbwbs, tbwbh, valid_bwb100);
    $setuphold (posedge CLK &&& WEA, posedge DA[101], tdas, tdah, valid_da101);
    $setuphold (posedge CLK &&& WEA, negedge DA[101], tdas, tdah, valid_da101);
    $setuphold (posedge CLK &&& WEB, posedge DB[101], tdbs, tdbh, valid_db101);
    $setuphold (posedge CLK &&& WEB, negedge DB[101], tdbs, tdbh, valid_db101);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[101], tbwas, tbwah, valid_bwa101);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[101], tbwas, tbwah, valid_bwa101);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[101], tbwbs, tbwbh, valid_bwb101);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[101], tbwbs, tbwbh, valid_bwb101);
    $setuphold (posedge CLK &&& WEA, posedge DA[102], tdas, tdah, valid_da102);
    $setuphold (posedge CLK &&& WEA, negedge DA[102], tdas, tdah, valid_da102);
    $setuphold (posedge CLK &&& WEB, posedge DB[102], tdbs, tdbh, valid_db102);
    $setuphold (posedge CLK &&& WEB, negedge DB[102], tdbs, tdbh, valid_db102);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[102], tbwas, tbwah, valid_bwa102);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[102], tbwas, tbwah, valid_bwa102);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[102], tbwbs, tbwbh, valid_bwb102);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[102], tbwbs, tbwbh, valid_bwb102);
    $setuphold (posedge CLK &&& WEA, posedge DA[103], tdas, tdah, valid_da103);
    $setuphold (posedge CLK &&& WEA, negedge DA[103], tdas, tdah, valid_da103);
    $setuphold (posedge CLK &&& WEB, posedge DB[103], tdbs, tdbh, valid_db103);
    $setuphold (posedge CLK &&& WEB, negedge DB[103], tdbs, tdbh, valid_db103);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[103], tbwas, tbwah, valid_bwa103);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[103], tbwas, tbwah, valid_bwa103);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[103], tbwbs, tbwbh, valid_bwb103);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[103], tbwbs, tbwbh, valid_bwb103);
    $setuphold (posedge CLK &&& WEA, posedge DA[104], tdas, tdah, valid_da104);
    $setuphold (posedge CLK &&& WEA, negedge DA[104], tdas, tdah, valid_da104);
    $setuphold (posedge CLK &&& WEB, posedge DB[104], tdbs, tdbh, valid_db104);
    $setuphold (posedge CLK &&& WEB, negedge DB[104], tdbs, tdbh, valid_db104);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[104], tbwas, tbwah, valid_bwa104);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[104], tbwas, tbwah, valid_bwa104);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[104], tbwbs, tbwbh, valid_bwb104);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[104], tbwbs, tbwbh, valid_bwb104);
    $setuphold (posedge CLK &&& WEA, posedge DA[105], tdas, tdah, valid_da105);
    $setuphold (posedge CLK &&& WEA, negedge DA[105], tdas, tdah, valid_da105);
    $setuphold (posedge CLK &&& WEB, posedge DB[105], tdbs, tdbh, valid_db105);
    $setuphold (posedge CLK &&& WEB, negedge DB[105], tdbs, tdbh, valid_db105);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[105], tbwas, tbwah, valid_bwa105);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[105], tbwas, tbwah, valid_bwa105);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[105], tbwbs, tbwbh, valid_bwb105);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[105], tbwbs, tbwbh, valid_bwb105);
    $setuphold (posedge CLK &&& WEA, posedge DA[106], tdas, tdah, valid_da106);
    $setuphold (posedge CLK &&& WEA, negedge DA[106], tdas, tdah, valid_da106);
    $setuphold (posedge CLK &&& WEB, posedge DB[106], tdbs, tdbh, valid_db106);
    $setuphold (posedge CLK &&& WEB, negedge DB[106], tdbs, tdbh, valid_db106);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[106], tbwas, tbwah, valid_bwa106);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[106], tbwas, tbwah, valid_bwa106);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[106], tbwbs, tbwbh, valid_bwb106);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[106], tbwbs, tbwbh, valid_bwb106);
    $setuphold (posedge CLK &&& WEA, posedge DA[107], tdas, tdah, valid_da107);
    $setuphold (posedge CLK &&& WEA, negedge DA[107], tdas, tdah, valid_da107);
    $setuphold (posedge CLK &&& WEB, posedge DB[107], tdbs, tdbh, valid_db107);
    $setuphold (posedge CLK &&& WEB, negedge DB[107], tdbs, tdbh, valid_db107);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[107], tbwas, tbwah, valid_bwa107);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[107], tbwas, tbwah, valid_bwa107);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[107], tbwbs, tbwbh, valid_bwb107);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[107], tbwbs, tbwbh, valid_bwb107);
    $setuphold (posedge CLK &&& WEA, posedge DA[108], tdas, tdah, valid_da108);
    $setuphold (posedge CLK &&& WEA, negedge DA[108], tdas, tdah, valid_da108);
    $setuphold (posedge CLK &&& WEB, posedge DB[108], tdbs, tdbh, valid_db108);
    $setuphold (posedge CLK &&& WEB, negedge DB[108], tdbs, tdbh, valid_db108);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[108], tbwas, tbwah, valid_bwa108);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[108], tbwas, tbwah, valid_bwa108);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[108], tbwbs, tbwbh, valid_bwb108);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[108], tbwbs, tbwbh, valid_bwb108);
    $setuphold (posedge CLK &&& WEA, posedge DA[109], tdas, tdah, valid_da109);
    $setuphold (posedge CLK &&& WEA, negedge DA[109], tdas, tdah, valid_da109);
    $setuphold (posedge CLK &&& WEB, posedge DB[109], tdbs, tdbh, valid_db109);
    $setuphold (posedge CLK &&& WEB, negedge DB[109], tdbs, tdbh, valid_db109);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[109], tbwas, tbwah, valid_bwa109);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[109], tbwas, tbwah, valid_bwa109);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[109], tbwbs, tbwbh, valid_bwb109);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[109], tbwbs, tbwbh, valid_bwb109);
    $setuphold (posedge CLK &&& WEA, posedge DA[110], tdas, tdah, valid_da110);
    $setuphold (posedge CLK &&& WEA, negedge DA[110], tdas, tdah, valid_da110);
    $setuphold (posedge CLK &&& WEB, posedge DB[110], tdbs, tdbh, valid_db110);
    $setuphold (posedge CLK &&& WEB, negedge DB[110], tdbs, tdbh, valid_db110);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[110], tbwas, tbwah, valid_bwa110);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[110], tbwas, tbwah, valid_bwa110);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[110], tbwbs, tbwbh, valid_bwb110);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[110], tbwbs, tbwbh, valid_bwb110);
    $setuphold (posedge CLK &&& WEA, posedge DA[111], tdas, tdah, valid_da111);
    $setuphold (posedge CLK &&& WEA, negedge DA[111], tdas, tdah, valid_da111);
    $setuphold (posedge CLK &&& WEB, posedge DB[111], tdbs, tdbh, valid_db111);
    $setuphold (posedge CLK &&& WEB, negedge DB[111], tdbs, tdbh, valid_db111);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[111], tbwas, tbwah, valid_bwa111);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[111], tbwas, tbwah, valid_bwa111);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[111], tbwbs, tbwbh, valid_bwb111);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[111], tbwbs, tbwbh, valid_bwb111);
    $setuphold (posedge CLK &&& WEA, posedge DA[112], tdas, tdah, valid_da112);
    $setuphold (posedge CLK &&& WEA, negedge DA[112], tdas, tdah, valid_da112);
    $setuphold (posedge CLK &&& WEB, posedge DB[112], tdbs, tdbh, valid_db112);
    $setuphold (posedge CLK &&& WEB, negedge DB[112], tdbs, tdbh, valid_db112);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[112], tbwas, tbwah, valid_bwa112);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[112], tbwas, tbwah, valid_bwa112);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[112], tbwbs, tbwbh, valid_bwb112);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[112], tbwbs, tbwbh, valid_bwb112);
    $setuphold (posedge CLK &&& WEA, posedge DA[113], tdas, tdah, valid_da113);
    $setuphold (posedge CLK &&& WEA, negedge DA[113], tdas, tdah, valid_da113);
    $setuphold (posedge CLK &&& WEB, posedge DB[113], tdbs, tdbh, valid_db113);
    $setuphold (posedge CLK &&& WEB, negedge DB[113], tdbs, tdbh, valid_db113);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[113], tbwas, tbwah, valid_bwa113);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[113], tbwas, tbwah, valid_bwa113);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[113], tbwbs, tbwbh, valid_bwb113);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[113], tbwbs, tbwbh, valid_bwb113);
    $setuphold (posedge CLK &&& WEA, posedge DA[114], tdas, tdah, valid_da114);
    $setuphold (posedge CLK &&& WEA, negedge DA[114], tdas, tdah, valid_da114);
    $setuphold (posedge CLK &&& WEB, posedge DB[114], tdbs, tdbh, valid_db114);
    $setuphold (posedge CLK &&& WEB, negedge DB[114], tdbs, tdbh, valid_db114);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[114], tbwas, tbwah, valid_bwa114);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[114], tbwas, tbwah, valid_bwa114);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[114], tbwbs, tbwbh, valid_bwb114);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[114], tbwbs, tbwbh, valid_bwb114);
    $setuphold (posedge CLK &&& WEA, posedge DA[115], tdas, tdah, valid_da115);
    $setuphold (posedge CLK &&& WEA, negedge DA[115], tdas, tdah, valid_da115);
    $setuphold (posedge CLK &&& WEB, posedge DB[115], tdbs, tdbh, valid_db115);
    $setuphold (posedge CLK &&& WEB, negedge DB[115], tdbs, tdbh, valid_db115);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[115], tbwas, tbwah, valid_bwa115);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[115], tbwas, tbwah, valid_bwa115);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[115], tbwbs, tbwbh, valid_bwb115);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[115], tbwbs, tbwbh, valid_bwb115);
    $setuphold (posedge CLK &&& WEA, posedge DA[116], tdas, tdah, valid_da116);
    $setuphold (posedge CLK &&& WEA, negedge DA[116], tdas, tdah, valid_da116);
    $setuphold (posedge CLK &&& WEB, posedge DB[116], tdbs, tdbh, valid_db116);
    $setuphold (posedge CLK &&& WEB, negedge DB[116], tdbs, tdbh, valid_db116);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[116], tbwas, tbwah, valid_bwa116);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[116], tbwas, tbwah, valid_bwa116);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[116], tbwbs, tbwbh, valid_bwb116);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[116], tbwbs, tbwbh, valid_bwb116);
    $setuphold (posedge CLK &&& WEA, posedge DA[117], tdas, tdah, valid_da117);
    $setuphold (posedge CLK &&& WEA, negedge DA[117], tdas, tdah, valid_da117);
    $setuphold (posedge CLK &&& WEB, posedge DB[117], tdbs, tdbh, valid_db117);
    $setuphold (posedge CLK &&& WEB, negedge DB[117], tdbs, tdbh, valid_db117);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[117], tbwas, tbwah, valid_bwa117);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[117], tbwas, tbwah, valid_bwa117);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[117], tbwbs, tbwbh, valid_bwb117);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[117], tbwbs, tbwbh, valid_bwb117);
    $setuphold (posedge CLK &&& WEA, posedge DA[118], tdas, tdah, valid_da118);
    $setuphold (posedge CLK &&& WEA, negedge DA[118], tdas, tdah, valid_da118);
    $setuphold (posedge CLK &&& WEB, posedge DB[118], tdbs, tdbh, valid_db118);
    $setuphold (posedge CLK &&& WEB, negedge DB[118], tdbs, tdbh, valid_db118);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[118], tbwas, tbwah, valid_bwa118);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[118], tbwas, tbwah, valid_bwa118);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[118], tbwbs, tbwbh, valid_bwb118);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[118], tbwbs, tbwbh, valid_bwb118);
    $setuphold (posedge CLK &&& WEA, posedge DA[119], tdas, tdah, valid_da119);
    $setuphold (posedge CLK &&& WEA, negedge DA[119], tdas, tdah, valid_da119);
    $setuphold (posedge CLK &&& WEB, posedge DB[119], tdbs, tdbh, valid_db119);
    $setuphold (posedge CLK &&& WEB, negedge DB[119], tdbs, tdbh, valid_db119);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[119], tbwas, tbwah, valid_bwa119);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[119], tbwas, tbwah, valid_bwa119);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[119], tbwbs, tbwbh, valid_bwb119);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[119], tbwbs, tbwbh, valid_bwb119);
    $setuphold (posedge CLK &&& WEA, posedge DA[120], tdas, tdah, valid_da120);
    $setuphold (posedge CLK &&& WEA, negedge DA[120], tdas, tdah, valid_da120);
    $setuphold (posedge CLK &&& WEB, posedge DB[120], tdbs, tdbh, valid_db120);
    $setuphold (posedge CLK &&& WEB, negedge DB[120], tdbs, tdbh, valid_db120);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[120], tbwas, tbwah, valid_bwa120);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[120], tbwas, tbwah, valid_bwa120);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[120], tbwbs, tbwbh, valid_bwb120);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[120], tbwbs, tbwbh, valid_bwb120);
    $setuphold (posedge CLK &&& WEA, posedge DA[121], tdas, tdah, valid_da121);
    $setuphold (posedge CLK &&& WEA, negedge DA[121], tdas, tdah, valid_da121);
    $setuphold (posedge CLK &&& WEB, posedge DB[121], tdbs, tdbh, valid_db121);
    $setuphold (posedge CLK &&& WEB, negedge DB[121], tdbs, tdbh, valid_db121);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[121], tbwas, tbwah, valid_bwa121);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[121], tbwas, tbwah, valid_bwa121);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[121], tbwbs, tbwbh, valid_bwb121);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[121], tbwbs, tbwbh, valid_bwb121);
    $setuphold (posedge CLK &&& WEA, posedge DA[122], tdas, tdah, valid_da122);
    $setuphold (posedge CLK &&& WEA, negedge DA[122], tdas, tdah, valid_da122);
    $setuphold (posedge CLK &&& WEB, posedge DB[122], tdbs, tdbh, valid_db122);
    $setuphold (posedge CLK &&& WEB, negedge DB[122], tdbs, tdbh, valid_db122);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[122], tbwas, tbwah, valid_bwa122);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[122], tbwas, tbwah, valid_bwa122);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[122], tbwbs, tbwbh, valid_bwb122);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[122], tbwbs, tbwbh, valid_bwb122);
    $setuphold (posedge CLK &&& WEA, posedge DA[123], tdas, tdah, valid_da123);
    $setuphold (posedge CLK &&& WEA, negedge DA[123], tdas, tdah, valid_da123);
    $setuphold (posedge CLK &&& WEB, posedge DB[123], tdbs, tdbh, valid_db123);
    $setuphold (posedge CLK &&& WEB, negedge DB[123], tdbs, tdbh, valid_db123);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[123], tbwas, tbwah, valid_bwa123);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[123], tbwas, tbwah, valid_bwa123);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[123], tbwbs, tbwbh, valid_bwb123);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[123], tbwbs, tbwbh, valid_bwb123);
    $setuphold (posedge CLK &&& WEA, posedge DA[124], tdas, tdah, valid_da124);
    $setuphold (posedge CLK &&& WEA, negedge DA[124], tdas, tdah, valid_da124);
    $setuphold (posedge CLK &&& WEB, posedge DB[124], tdbs, tdbh, valid_db124);
    $setuphold (posedge CLK &&& WEB, negedge DB[124], tdbs, tdbh, valid_db124);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[124], tbwas, tbwah, valid_bwa124);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[124], tbwas, tbwah, valid_bwa124);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[124], tbwbs, tbwbh, valid_bwb124);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[124], tbwbs, tbwbh, valid_bwb124);
    $setuphold (posedge CLK &&& WEA, posedge DA[125], tdas, tdah, valid_da125);
    $setuphold (posedge CLK &&& WEA, negedge DA[125], tdas, tdah, valid_da125);
    $setuphold (posedge CLK &&& WEB, posedge DB[125], tdbs, tdbh, valid_db125);
    $setuphold (posedge CLK &&& WEB, negedge DB[125], tdbs, tdbh, valid_db125);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[125], tbwas, tbwah, valid_bwa125);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[125], tbwas, tbwah, valid_bwa125);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[125], tbwbs, tbwbh, valid_bwb125);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[125], tbwbs, tbwbh, valid_bwb125);
    $setuphold (posedge CLK &&& WEA, posedge DA[126], tdas, tdah, valid_da126);
    $setuphold (posedge CLK &&& WEA, negedge DA[126], tdas, tdah, valid_da126);
    $setuphold (posedge CLK &&& WEB, posedge DB[126], tdbs, tdbh, valid_db126);
    $setuphold (posedge CLK &&& WEB, negedge DB[126], tdbs, tdbh, valid_db126);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[126], tbwas, tbwah, valid_bwa126);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[126], tbwas, tbwah, valid_bwa126);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[126], tbwbs, tbwbh, valid_bwb126);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[126], tbwbs, tbwbh, valid_bwb126);
    $setuphold (posedge CLK &&& WEA, posedge DA[127], tdas, tdah, valid_da127);
    $setuphold (posedge CLK &&& WEA, negedge DA[127], tdas, tdah, valid_da127);
    $setuphold (posedge CLK &&& WEB, posedge DB[127], tdbs, tdbh, valid_db127);
    $setuphold (posedge CLK &&& WEB, negedge DB[127], tdbs, tdbh, valid_db127);
 
    $setuphold (posedge CLK &&& WEA, posedge BWEBA[127], tbwas, tbwah, valid_bwa127);
    $setuphold (posedge CLK &&& WEA, negedge BWEBA[127], tbwas, tbwah, valid_bwa127);
    $setuphold (posedge CLK &&& WEB, posedge BWEBB[127], tbwbs, tbwbh, valid_bwb127);
    $setuphold (posedge CLK &&& WEB, negedge BWEBB[127], tbwbs, tbwbh, valid_bwb127);
    $setuphold (posedge CLK &&& CSA, posedge WEBA, twas, twah, valid_wea);
    $setuphold (posedge CLK &&& CSA, negedge WEBA, twas, twah, valid_wea);
    $setuphold (posedge CLK &&& CSB, posedge WEBB, twbs, twbh, valid_web);
    $setuphold (posedge CLK &&& CSB, negedge WEBB, twbs, twbh, valid_web);

    $setuphold (posedge CLK, posedge CEBA, tcas, tcah, valid_cea);
    $setuphold (posedge CLK, negedge CEBA, tcas, tcah, valid_cea);
    $setuphold (posedge CLK, posedge CEBB, tcbs, tcbh, valid_ceb);
    $setuphold (posedge CLK, negedge CEBB, tcbs, tcbh, valid_ceb);

    $width (negedge CLK &&& check_ceb, tckl, 0, valid_ck);
    $width (posedge CLK &&& check_ceb, tckh, 0, valid_ck);
    $period (posedge CLK &&& check_ceb, tcyc, valid_ck);
    $period (negedge CLK &&& check_ceb, tcyc, valid_ck);


if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[0] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[0] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[0] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[0] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[0] => (QA[0] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[0] => (QA[0] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[0] => (QB[0] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[0] => (QB[0] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[0] => (QA[0] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[0] => (QA[0] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[0] => (QB[0] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[0] => (QB[0] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[1] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[1] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[1] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[1] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[1] => (QA[1] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[1] => (QA[1] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[1] => (QB[1] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[1] => (QB[1] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[1] => (QA[1] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[1] => (QA[1] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[1] => (QB[1] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[1] => (QB[1] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[2] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[2] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[2] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[2] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[2] => (QA[2] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[2] => (QA[2] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[2] => (QB[2] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[2] => (QB[2] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[2] => (QA[2] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[2] => (QA[2] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[2] => (QB[2] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[2] => (QB[2] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[3] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[3] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[3] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[3] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[3] => (QA[3] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[3] => (QA[3] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[3] => (QB[3] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[3] => (QB[3] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[3] => (QA[3] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[3] => (QA[3] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[3] => (QB[3] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[3] => (QB[3] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[4] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[4] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[4] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[4] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[4] => (QA[4] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[4] => (QA[4] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[4] => (QB[4] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[4] => (QB[4] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[4] => (QA[4] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[4] => (QA[4] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[4] => (QB[4] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[4] => (QB[4] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[5] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[5] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[5] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[5] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[5] => (QA[5] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[5] => (QA[5] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[5] => (QB[5] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[5] => (QB[5] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[5] => (QA[5] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[5] => (QA[5] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[5] => (QB[5] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[5] => (QB[5] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[6] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[6] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[6] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[6] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[6] => (QA[6] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[6] => (QA[6] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[6] => (QB[6] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[6] => (QB[6] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[6] => (QA[6] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[6] => (QA[6] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[6] => (QB[6] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[6] => (QB[6] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[7] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[7] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[7] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[7] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[7] => (QA[7] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[7] => (QA[7] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[7] => (QB[7] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[7] => (QB[7] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[7] => (QA[7] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[7] => (QA[7] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[7] => (QB[7] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[7] => (QB[7] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[8] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[8] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[8] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[8] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[8] => (QA[8] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[8] => (QA[8] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[8] => (QB[8] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[8] => (QB[8] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[8] => (QA[8] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[8] => (QA[8] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[8] => (QB[8] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[8] => (QB[8] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[9] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[9] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[9] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[9] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[9] => (QA[9] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[9] => (QA[9] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[9] => (QB[9] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[9] => (QB[9] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[9] => (QA[9] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[9] => (QA[9] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[9] => (QB[9] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[9] => (QB[9] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[10] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[10] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[10] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[10] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[10] => (QA[10] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[10] => (QA[10] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[10] => (QB[10] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[10] => (QB[10] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[10] => (QA[10] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[10] => (QA[10] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[10] => (QB[10] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[10] => (QB[10] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[11] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[11] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[11] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[11] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[11] => (QA[11] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[11] => (QA[11] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[11] => (QB[11] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[11] => (QB[11] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[11] => (QA[11] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[11] => (QA[11] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[11] => (QB[11] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[11] => (QB[11] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[12] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[12] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[12] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[12] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[12] => (QA[12] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[12] => (QA[12] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[12] => (QB[12] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[12] => (QB[12] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[12] => (QA[12] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[12] => (QA[12] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[12] => (QB[12] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[12] => (QB[12] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[13] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[13] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[13] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[13] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[13] => (QA[13] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[13] => (QA[13] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[13] => (QB[13] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[13] => (QB[13] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[13] => (QA[13] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[13] => (QA[13] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[13] => (QB[13] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[13] => (QB[13] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[14] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[14] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[14] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[14] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[14] => (QA[14] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[14] => (QA[14] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[14] => (QB[14] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[14] => (QB[14] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[14] => (QA[14] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[14] => (QA[14] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[14] => (QB[14] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[14] => (QB[14] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[15] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[15] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[15] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[15] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[15] => (QA[15] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[15] => (QA[15] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[15] => (QB[15] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[15] => (QB[15] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[15] => (QA[15] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[15] => (QA[15] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[15] => (QB[15] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[15] => (QB[15] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[16] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[16] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[16] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[16] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[16] => (QA[16] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[16] => (QA[16] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[16] => (QB[16] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[16] => (QB[16] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[16] => (QA[16] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[16] => (QA[16] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[16] => (QB[16] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[16] => (QB[16] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[17] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[17] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[17] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[17] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[17] => (QA[17] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[17] => (QA[17] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[17] => (QB[17] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[17] => (QB[17] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[17] => (QA[17] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[17] => (QA[17] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[17] => (QB[17] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[17] => (QB[17] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[18] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[18] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[18] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[18] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[18] => (QA[18] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[18] => (QA[18] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[18] => (QB[18] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[18] => (QB[18] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[18] => (QA[18] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[18] => (QA[18] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[18] => (QB[18] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[18] => (QB[18] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[19] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[19] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[19] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[19] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[19] => (QA[19] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[19] => (QA[19] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[19] => (QB[19] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[19] => (QB[19] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[19] => (QA[19] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[19] => (QA[19] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[19] => (QB[19] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[19] => (QB[19] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[20] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[20] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[20] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[20] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[20] => (QA[20] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[20] => (QA[20] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[20] => (QB[20] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[20] => (QB[20] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[20] => (QA[20] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[20] => (QA[20] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[20] => (QB[20] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[20] => (QB[20] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[21] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[21] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[21] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[21] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[21] => (QA[21] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[21] => (QA[21] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[21] => (QB[21] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[21] => (QB[21] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[21] => (QA[21] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[21] => (QA[21] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[21] => (QB[21] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[21] => (QB[21] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[22] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[22] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[22] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[22] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[22] => (QA[22] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[22] => (QA[22] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[22] => (QB[22] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[22] => (QB[22] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[22] => (QA[22] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[22] => (QA[22] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[22] => (QB[22] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[22] => (QB[22] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[23] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[23] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[23] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[23] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[23] => (QA[23] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[23] => (QA[23] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[23] => (QB[23] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[23] => (QB[23] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[23] => (QA[23] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[23] => (QA[23] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[23] => (QB[23] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[23] => (QB[23] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[24] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[24] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[24] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[24] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[24] => (QA[24] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[24] => (QA[24] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[24] => (QB[24] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[24] => (QB[24] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[24] => (QA[24] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[24] => (QA[24] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[24] => (QB[24] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[24] => (QB[24] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[25] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[25] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[25] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[25] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[25] => (QA[25] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[25] => (QA[25] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[25] => (QB[25] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[25] => (QB[25] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[25] => (QA[25] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[25] => (QA[25] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[25] => (QB[25] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[25] => (QB[25] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[26] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[26] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[26] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[26] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[26] => (QA[26] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[26] => (QA[26] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[26] => (QB[26] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[26] => (QB[26] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[26] => (QA[26] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[26] => (QA[26] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[26] => (QB[26] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[26] => (QB[26] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[27] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[27] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[27] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[27] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[27] => (QA[27] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[27] => (QA[27] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[27] => (QB[27] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[27] => (QB[27] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[27] => (QA[27] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[27] => (QA[27] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[27] => (QB[27] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[27] => (QB[27] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[28] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[28] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[28] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[28] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[28] => (QA[28] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[28] => (QA[28] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[28] => (QB[28] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[28] => (QB[28] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[28] => (QA[28] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[28] => (QA[28] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[28] => (QB[28] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[28] => (QB[28] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[29] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[29] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[29] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[29] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[29] => (QA[29] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[29] => (QA[29] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[29] => (QB[29] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[29] => (QB[29] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[29] => (QA[29] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[29] => (QA[29] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[29] => (QB[29] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[29] => (QB[29] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[30] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[30] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[30] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[30] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[30] => (QA[30] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[30] => (QA[30] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[30] => (QB[30] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[30] => (QB[30] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[30] => (QA[30] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[30] => (QA[30] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[30] => (QB[30] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[30] => (QB[30] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[31] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[31] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[31] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[31] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[31] => (QA[31] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[31] => (QA[31] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[31] => (QB[31] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[31] => (QB[31] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[31] => (QA[31] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[31] => (QA[31] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[31] => (QB[31] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[31] => (QB[31] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[32] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[32] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[32] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[32] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[32] => (QA[32] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[32] => (QA[32] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[32] => (QB[32] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[32] => (QB[32] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[32] => (QA[32] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[32] => (QA[32] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[32] => (QB[32] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[32] => (QB[32] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[33] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[33] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[33] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[33] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[33] => (QA[33] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[33] => (QA[33] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[33] => (QB[33] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[33] => (QB[33] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[33] => (QA[33] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[33] => (QA[33] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[33] => (QB[33] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[33] => (QB[33] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[34] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[34] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[34] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[34] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[34] => (QA[34] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[34] => (QA[34] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[34] => (QB[34] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[34] => (QB[34] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[34] => (QA[34] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[34] => (QA[34] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[34] => (QB[34] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[34] => (QB[34] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[35] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[35] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[35] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[35] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[35] => (QA[35] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[35] => (QA[35] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[35] => (QB[35] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[35] => (QB[35] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[35] => (QA[35] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[35] => (QA[35] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[35] => (QB[35] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[35] => (QB[35] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[36] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[36] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[36] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[36] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[36] => (QA[36] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[36] => (QA[36] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[36] => (QB[36] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[36] => (QB[36] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[36] => (QA[36] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[36] => (QA[36] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[36] => (QB[36] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[36] => (QB[36] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[37] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[37] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[37] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[37] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[37] => (QA[37] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[37] => (QA[37] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[37] => (QB[37] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[37] => (QB[37] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[37] => (QA[37] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[37] => (QA[37] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[37] => (QB[37] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[37] => (QB[37] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[38] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[38] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[38] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[38] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[38] => (QA[38] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[38] => (QA[38] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[38] => (QB[38] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[38] => (QB[38] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[38] => (QA[38] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[38] => (QA[38] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[38] => (QB[38] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[38] => (QB[38] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[39] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[39] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[39] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[39] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[39] => (QA[39] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[39] => (QA[39] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[39] => (QB[39] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[39] => (QB[39] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[39] => (QA[39] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[39] => (QA[39] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[39] => (QB[39] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[39] => (QB[39] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[40] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[40] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[40] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[40] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[40] => (QA[40] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[40] => (QA[40] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[40] => (QB[40] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[40] => (QB[40] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[40] => (QA[40] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[40] => (QA[40] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[40] => (QB[40] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[40] => (QB[40] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[41] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[41] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[41] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[41] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[41] => (QA[41] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[41] => (QA[41] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[41] => (QB[41] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[41] => (QB[41] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[41] => (QA[41] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[41] => (QA[41] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[41] => (QB[41] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[41] => (QB[41] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[42] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[42] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[42] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[42] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[42] => (QA[42] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[42] => (QA[42] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[42] => (QB[42] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[42] => (QB[42] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[42] => (QA[42] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[42] => (QA[42] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[42] => (QB[42] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[42] => (QB[42] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[43] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[43] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[43] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[43] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[43] => (QA[43] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[43] => (QA[43] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[43] => (QB[43] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[43] => (QB[43] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[43] => (QA[43] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[43] => (QA[43] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[43] => (QB[43] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[43] => (QB[43] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[44] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[44] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[44] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[44] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[44] => (QA[44] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[44] => (QA[44] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[44] => (QB[44] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[44] => (QB[44] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[44] => (QA[44] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[44] => (QA[44] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[44] => (QB[44] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[44] => (QB[44] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[45] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[45] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[45] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[45] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[45] => (QA[45] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[45] => (QA[45] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[45] => (QB[45] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[45] => (QB[45] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[45] => (QA[45] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[45] => (QA[45] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[45] => (QB[45] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[45] => (QB[45] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[46] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[46] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[46] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[46] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[46] => (QA[46] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[46] => (QA[46] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[46] => (QB[46] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[46] => (QB[46] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[46] => (QA[46] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[46] => (QA[46] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[46] => (QB[46] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[46] => (QB[46] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[47] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[47] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[47] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[47] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[47] => (QA[47] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[47] => (QA[47] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[47] => (QB[47] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[47] => (QB[47] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[47] => (QA[47] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[47] => (QA[47] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[47] => (QB[47] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[47] => (QB[47] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[48] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[48] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[48] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[48] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[48] => (QA[48] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[48] => (QA[48] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[48] => (QB[48] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[48] => (QB[48] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[48] => (QA[48] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[48] => (QA[48] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[48] => (QB[48] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[48] => (QB[48] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[49] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[49] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[49] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[49] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[49] => (QA[49] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[49] => (QA[49] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[49] => (QB[49] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[49] => (QB[49] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[49] => (QA[49] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[49] => (QA[49] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[49] => (QB[49] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[49] => (QB[49] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[50] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[50] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[50] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[50] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[50] => (QA[50] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[50] => (QA[50] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[50] => (QB[50] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[50] => (QB[50] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[50] => (QA[50] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[50] => (QA[50] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[50] => (QB[50] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[50] => (QB[50] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[51] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[51] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[51] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[51] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[51] => (QA[51] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[51] => (QA[51] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[51] => (QB[51] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[51] => (QB[51] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[51] => (QA[51] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[51] => (QA[51] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[51] => (QB[51] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[51] => (QB[51] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[52] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[52] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[52] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[52] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[52] => (QA[52] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[52] => (QA[52] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[52] => (QB[52] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[52] => (QB[52] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[52] => (QA[52] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[52] => (QA[52] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[52] => (QB[52] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[52] => (QB[52] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[53] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[53] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[53] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[53] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[53] => (QA[53] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[53] => (QA[53] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[53] => (QB[53] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[53] => (QB[53] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[53] => (QA[53] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[53] => (QA[53] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[53] => (QB[53] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[53] => (QB[53] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[54] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[54] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[54] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[54] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[54] => (QA[54] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[54] => (QA[54] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[54] => (QB[54] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[54] => (QB[54] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[54] => (QA[54] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[54] => (QA[54] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[54] => (QB[54] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[54] => (QB[54] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[55] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[55] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[55] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[55] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[55] => (QA[55] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[55] => (QA[55] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[55] => (QB[55] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[55] => (QB[55] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[55] => (QA[55] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[55] => (QA[55] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[55] => (QB[55] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[55] => (QB[55] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[56] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[56] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[56] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[56] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[56] => (QA[56] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[56] => (QA[56] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[56] => (QB[56] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[56] => (QB[56] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[56] => (QA[56] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[56] => (QA[56] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[56] => (QB[56] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[56] => (QB[56] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[57] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[57] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[57] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[57] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[57] => (QA[57] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[57] => (QA[57] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[57] => (QB[57] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[57] => (QB[57] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[57] => (QA[57] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[57] => (QA[57] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[57] => (QB[57] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[57] => (QB[57] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[58] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[58] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[58] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[58] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[58] => (QA[58] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[58] => (QA[58] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[58] => (QB[58] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[58] => (QB[58] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[58] => (QA[58] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[58] => (QA[58] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[58] => (QB[58] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[58] => (QB[58] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[59] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[59] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[59] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[59] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[59] => (QA[59] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[59] => (QA[59] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[59] => (QB[59] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[59] => (QB[59] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[59] => (QA[59] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[59] => (QA[59] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[59] => (QB[59] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[59] => (QB[59] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[60] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[60] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[60] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[60] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[60] => (QA[60] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[60] => (QA[60] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[60] => (QB[60] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[60] => (QB[60] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[60] => (QA[60] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[60] => (QA[60] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[60] => (QB[60] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[60] => (QB[60] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[61] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[61] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[61] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[61] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[61] => (QA[61] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[61] => (QA[61] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[61] => (QB[61] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[61] => (QB[61] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[61] => (QA[61] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[61] => (QA[61] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[61] => (QB[61] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[61] => (QB[61] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[62] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[62] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[62] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[62] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[62] => (QA[62] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[62] => (QA[62] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[62] => (QB[62] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[62] => (QB[62] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[62] => (QA[62] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[62] => (QA[62] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[62] => (QB[62] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[62] => (QB[62] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[63] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[63] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[63] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[63] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[63] => (QA[63] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[63] => (QA[63] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[63] => (QB[63] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[63] => (QB[63] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[63] => (QA[63] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[63] => (QA[63] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[63] => (QB[63] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[63] => (QB[63] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[64] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[64] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[64] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[64] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[64] => (QA[64] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[64] => (QA[64] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[64] => (QB[64] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[64] => (QB[64] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[64] => (QA[64] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[64] => (QA[64] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[64] => (QB[64] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[64] => (QB[64] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[65] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[65] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[65] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[65] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[65] => (QA[65] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[65] => (QA[65] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[65] => (QB[65] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[65] => (QB[65] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[65] => (QA[65] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[65] => (QA[65] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[65] => (QB[65] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[65] => (QB[65] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[66] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[66] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[66] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[66] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[66] => (QA[66] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[66] => (QA[66] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[66] => (QB[66] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[66] => (QB[66] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[66] => (QA[66] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[66] => (QA[66] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[66] => (QB[66] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[66] => (QB[66] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[67] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[67] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[67] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[67] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[67] => (QA[67] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[67] => (QA[67] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[67] => (QB[67] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[67] => (QB[67] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[67] => (QA[67] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[67] => (QA[67] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[67] => (QB[67] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[67] => (QB[67] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[68] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[68] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[68] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[68] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[68] => (QA[68] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[68] => (QA[68] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[68] => (QB[68] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[68] => (QB[68] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[68] => (QA[68] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[68] => (QA[68] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[68] => (QB[68] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[68] => (QB[68] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[69] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[69] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[69] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[69] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[69] => (QA[69] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[69] => (QA[69] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[69] => (QB[69] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[69] => (QB[69] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[69] => (QA[69] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[69] => (QA[69] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[69] => (QB[69] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[69] => (QB[69] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[70] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[70] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[70] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[70] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[70] => (QA[70] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[70] => (QA[70] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[70] => (QB[70] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[70] => (QB[70] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[70] => (QA[70] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[70] => (QA[70] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[70] => (QB[70] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[70] => (QB[70] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[71] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[71] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[71] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[71] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[71] => (QA[71] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[71] => (QA[71] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[71] => (QB[71] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[71] => (QB[71] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[71] => (QA[71] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[71] => (QA[71] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[71] => (QB[71] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[71] => (QB[71] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[72] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[72] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[72] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[72] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[72] => (QA[72] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[72] => (QA[72] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[72] => (QB[72] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[72] => (QB[72] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[72] => (QA[72] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[72] => (QA[72] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[72] => (QB[72] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[72] => (QB[72] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[73] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[73] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[73] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[73] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[73] => (QA[73] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[73] => (QA[73] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[73] => (QB[73] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[73] => (QB[73] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[73] => (QA[73] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[73] => (QA[73] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[73] => (QB[73] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[73] => (QB[73] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[74] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[74] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[74] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[74] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[74] => (QA[74] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[74] => (QA[74] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[74] => (QB[74] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[74] => (QB[74] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[74] => (QA[74] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[74] => (QA[74] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[74] => (QB[74] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[74] => (QB[74] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[75] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[75] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[75] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[75] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[75] => (QA[75] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[75] => (QA[75] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[75] => (QB[75] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[75] => (QB[75] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[75] => (QA[75] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[75] => (QA[75] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[75] => (QB[75] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[75] => (QB[75] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[76] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[76] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[76] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[76] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[76] => (QA[76] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[76] => (QA[76] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[76] => (QB[76] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[76] => (QB[76] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[76] => (QA[76] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[76] => (QA[76] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[76] => (QB[76] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[76] => (QB[76] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[77] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[77] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[77] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[77] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[77] => (QA[77] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[77] => (QA[77] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[77] => (QB[77] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[77] => (QB[77] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[77] => (QA[77] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[77] => (QA[77] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[77] => (QB[77] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[77] => (QB[77] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[78] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[78] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[78] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[78] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[78] => (QA[78] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[78] => (QA[78] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[78] => (QB[78] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[78] => (QB[78] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[78] => (QA[78] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[78] => (QA[78] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[78] => (QB[78] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[78] => (QB[78] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[79] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[79] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[79] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[79] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[79] => (QA[79] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[79] => (QA[79] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[79] => (QB[79] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[79] => (QB[79] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[79] => (QA[79] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[79] => (QA[79] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[79] => (QB[79] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[79] => (QB[79] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[80] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[80] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[80] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[80] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[80] => (QA[80] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[80] => (QA[80] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[80] => (QB[80] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[80] => (QB[80] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[80] => (QA[80] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[80] => (QA[80] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[80] => (QB[80] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[80] => (QB[80] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[81] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[81] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[81] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[81] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[81] => (QA[81] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[81] => (QA[81] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[81] => (QB[81] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[81] => (QB[81] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[81] => (QA[81] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[81] => (QA[81] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[81] => (QB[81] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[81] => (QB[81] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[82] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[82] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[82] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[82] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[82] => (QA[82] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[82] => (QA[82] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[82] => (QB[82] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[82] => (QB[82] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[82] => (QA[82] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[82] => (QA[82] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[82] => (QB[82] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[82] => (QB[82] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[83] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[83] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[83] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[83] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[83] => (QA[83] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[83] => (QA[83] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[83] => (QB[83] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[83] => (QB[83] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[83] => (QA[83] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[83] => (QA[83] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[83] => (QB[83] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[83] => (QB[83] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[84] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[84] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[84] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[84] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[84] => (QA[84] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[84] => (QA[84] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[84] => (QB[84] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[84] => (QB[84] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[84] => (QA[84] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[84] => (QA[84] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[84] => (QB[84] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[84] => (QB[84] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[85] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[85] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[85] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[85] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[85] => (QA[85] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[85] => (QA[85] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[85] => (QB[85] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[85] => (QB[85] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[85] => (QA[85] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[85] => (QA[85] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[85] => (QB[85] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[85] => (QB[85] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[86] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[86] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[86] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[86] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[86] => (QA[86] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[86] => (QA[86] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[86] => (QB[86] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[86] => (QB[86] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[86] => (QA[86] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[86] => (QA[86] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[86] => (QB[86] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[86] => (QB[86] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[87] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[87] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[87] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[87] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[87] => (QA[87] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[87] => (QA[87] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[87] => (QB[87] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[87] => (QB[87] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[87] => (QA[87] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[87] => (QA[87] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[87] => (QB[87] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[87] => (QB[87] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[88] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[88] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[88] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[88] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[88] => (QA[88] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[88] => (QA[88] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[88] => (QB[88] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[88] => (QB[88] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[88] => (QA[88] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[88] => (QA[88] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[88] => (QB[88] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[88] => (QB[88] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[89] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[89] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[89] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[89] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[89] => (QA[89] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[89] => (QA[89] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[89] => (QB[89] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[89] => (QB[89] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[89] => (QA[89] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[89] => (QA[89] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[89] => (QB[89] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[89] => (QB[89] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[90] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[90] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[90] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[90] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[90] => (QA[90] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[90] => (QA[90] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[90] => (QB[90] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[90] => (QB[90] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[90] => (QA[90] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[90] => (QA[90] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[90] => (QB[90] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[90] => (QB[90] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[91] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[91] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[91] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[91] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[91] => (QA[91] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[91] => (QA[91] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[91] => (QB[91] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[91] => (QB[91] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[91] => (QA[91] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[91] => (QA[91] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[91] => (QB[91] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[91] => (QB[91] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[92] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[92] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[92] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[92] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[92] => (QA[92] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[92] => (QA[92] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[92] => (QB[92] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[92] => (QB[92] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[92] => (QA[92] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[92] => (QA[92] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[92] => (QB[92] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[92] => (QB[92] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[93] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[93] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[93] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[93] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[93] => (QA[93] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[93] => (QA[93] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[93] => (QB[93] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[93] => (QB[93] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[93] => (QA[93] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[93] => (QA[93] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[93] => (QB[93] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[93] => (QB[93] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[94] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[94] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[94] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[94] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[94] => (QA[94] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[94] => (QA[94] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[94] => (QB[94] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[94] => (QB[94] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[94] => (QA[94] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[94] => (QA[94] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[94] => (QB[94] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[94] => (QB[94] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[95] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[95] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[95] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[95] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[95] => (QA[95] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[95] => (QA[95] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[95] => (QB[95] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[95] => (QB[95] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[95] => (QA[95] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[95] => (QA[95] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[95] => (QB[95] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[95] => (QB[95] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[96] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[96] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[96] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[96] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[96] => (QA[96] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[96] => (QA[96] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[96] => (QB[96] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[96] => (QB[96] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[96] => (QA[96] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[96] => (QA[96] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[96] => (QB[96] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[96] => (QB[96] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[97] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[97] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[97] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[97] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[97] => (QA[97] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[97] => (QA[97] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[97] => (QB[97] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[97] => (QB[97] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[97] => (QA[97] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[97] => (QA[97] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[97] => (QB[97] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[97] => (QB[97] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[98] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[98] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[98] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[98] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[98] => (QA[98] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[98] => (QA[98] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[98] => (QB[98] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[98] => (QB[98] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[98] => (QA[98] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[98] => (QA[98] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[98] => (QB[98] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[98] => (QB[98] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[99] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[99] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[99] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[99] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[99] => (QA[99] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[99] => (QA[99] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[99] => (QB[99] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[99] => (QB[99] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[99] => (QA[99] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[99] => (QA[99] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[99] => (QB[99] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[99] => (QB[99] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[100] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[100] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[100] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[100] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[100] => (QA[100] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[100] => (QA[100] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[100] => (QB[100] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[100] => (QB[100] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[100] => (QA[100] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[100] => (QA[100] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[100] => (QB[100] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[100] => (QB[100] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[101] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[101] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[101] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[101] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[101] => (QA[101] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[101] => (QA[101] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[101] => (QB[101] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[101] => (QB[101] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[101] => (QA[101] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[101] => (QA[101] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[101] => (QB[101] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[101] => (QB[101] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[102] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[102] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[102] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[102] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[102] => (QA[102] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[102] => (QA[102] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[102] => (QB[102] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[102] => (QB[102] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[102] => (QA[102] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[102] => (QA[102] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[102] => (QB[102] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[102] => (QB[102] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[103] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[103] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[103] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[103] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[103] => (QA[103] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[103] => (QA[103] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[103] => (QB[103] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[103] => (QB[103] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[103] => (QA[103] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[103] => (QA[103] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[103] => (QB[103] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[103] => (QB[103] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[104] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[104] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[104] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[104] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[104] => (QA[104] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[104] => (QA[104] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[104] => (QB[104] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[104] => (QB[104] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[104] => (QA[104] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[104] => (QA[104] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[104] => (QB[104] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[104] => (QB[104] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[105] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[105] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[105] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[105] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[105] => (QA[105] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[105] => (QA[105] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[105] => (QB[105] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[105] => (QB[105] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[105] => (QA[105] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[105] => (QA[105] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[105] => (QB[105] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[105] => (QB[105] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[106] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[106] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[106] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[106] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[106] => (QA[106] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[106] => (QA[106] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[106] => (QB[106] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[106] => (QB[106] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[106] => (QA[106] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[106] => (QA[106] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[106] => (QB[106] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[106] => (QB[106] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[107] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[107] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[107] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[107] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[107] => (QA[107] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[107] => (QA[107] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[107] => (QB[107] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[107] => (QB[107] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[107] => (QA[107] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[107] => (QA[107] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[107] => (QB[107] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[107] => (QB[107] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[108] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[108] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[108] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[108] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[108] => (QA[108] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[108] => (QA[108] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[108] => (QB[108] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[108] => (QB[108] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[108] => (QA[108] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[108] => (QA[108] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[108] => (QB[108] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[108] => (QB[108] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[109] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[109] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[109] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[109] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[109] => (QA[109] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[109] => (QA[109] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[109] => (QB[109] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[109] => (QB[109] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[109] => (QA[109] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[109] => (QA[109] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[109] => (QB[109] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[109] => (QB[109] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[110] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[110] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[110] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[110] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[110] => (QA[110] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[110] => (QA[110] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[110] => (QB[110] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[110] => (QB[110] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[110] => (QA[110] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[110] => (QA[110] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[110] => (QB[110] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[110] => (QB[110] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[111] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[111] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[111] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[111] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[111] => (QA[111] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[111] => (QA[111] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[111] => (QB[111] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[111] => (QB[111] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[111] => (QA[111] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[111] => (QA[111] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[111] => (QB[111] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[111] => (QB[111] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[112] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[112] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[112] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[112] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[112] => (QA[112] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[112] => (QA[112] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[112] => (QB[112] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[112] => (QB[112] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[112] => (QA[112] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[112] => (QA[112] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[112] => (QB[112] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[112] => (QB[112] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[113] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[113] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[113] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[113] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[113] => (QA[113] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[113] => (QA[113] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[113] => (QB[113] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[113] => (QB[113] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[113] => (QA[113] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[113] => (QA[113] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[113] => (QB[113] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[113] => (QB[113] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[114] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[114] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[114] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[114] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[114] => (QA[114] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[114] => (QA[114] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[114] => (QB[114] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[114] => (QB[114] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[114] => (QA[114] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[114] => (QA[114] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[114] => (QB[114] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[114] => (QB[114] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[115] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[115] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[115] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[115] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[115] => (QA[115] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[115] => (QA[115] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[115] => (QB[115] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[115] => (QB[115] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[115] => (QA[115] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[115] => (QA[115] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[115] => (QB[115] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[115] => (QB[115] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[116] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[116] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[116] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[116] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[116] => (QA[116] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[116] => (QA[116] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[116] => (QB[116] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[116] => (QB[116] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[116] => (QA[116] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[116] => (QA[116] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[116] => (QB[116] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[116] => (QB[116] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[117] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[117] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[117] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[117] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[117] => (QA[117] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[117] => (QA[117] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[117] => (QB[117] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[117] => (QB[117] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[117] => (QA[117] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[117] => (QA[117] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[117] => (QB[117] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[117] => (QB[117] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[118] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[118] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[118] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[118] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[118] => (QA[118] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[118] => (QA[118] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[118] => (QB[118] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[118] => (QB[118] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[118] => (QA[118] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[118] => (QA[118] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[118] => (QB[118] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[118] => (QB[118] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[119] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[119] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[119] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[119] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[119] => (QA[119] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[119] => (QA[119] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[119] => (QB[119] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[119] => (QB[119] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[119] => (QA[119] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[119] => (QA[119] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[119] => (QB[119] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[119] => (QB[119] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[120] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[120] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[120] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[120] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[120] => (QA[120] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[120] => (QA[120] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[120] => (QB[120] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[120] => (QB[120] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[120] => (QA[120] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[120] => (QA[120] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[120] => (QB[120] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[120] => (QB[120] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[121] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[121] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[121] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[121] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[121] => (QA[121] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[121] => (QA[121] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[121] => (QB[121] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[121] => (QB[121] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[121] => (QA[121] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[121] => (QA[121] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[121] => (QB[121] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[121] => (QB[121] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[122] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[122] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[122] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[122] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[122] => (QA[122] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[122] => (QA[122] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[122] => (QB[122] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[122] => (QB[122] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[122] => (QA[122] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[122] => (QA[122] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[122] => (QB[122] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[122] => (QB[122] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[123] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[123] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[123] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[123] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[123] => (QA[123] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[123] => (QA[123] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[123] => (QB[123] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[123] => (QB[123] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[123] => (QA[123] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[123] => (QA[123] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[123] => (QB[123] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[123] => (QB[123] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[124] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[124] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[124] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[124] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[124] => (QA[124] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[124] => (QA[124] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[124] => (QB[124] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[124] => (QB[124] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[124] => (QA[124] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[124] => (QA[124] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[124] => (QB[124] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[124] => (QB[124] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[125] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[125] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[125] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[125] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[125] => (QA[125] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[125] => (QA[125] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[125] => (QB[125] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[125] => (QB[125] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[125] => (QA[125] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[125] => (QA[125] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[125] => (QB[125] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[125] => (QB[125] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[126] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[126] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[126] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[126] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[126] => (QA[126] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[126] => (QA[126] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[126] => (QB[126] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[126] => (QB[126] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[126] => (QA[126] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[126] => (QA[126] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[126] => (QB[126] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[126] => (QB[126] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(!AWT & !CEBA & WEBA) (posedge CLK => (QA[127] : 1'bx)) = (tcda,tcda,tholda,tcda,tholda,tcda);
if(!AWT & !CEBB & WEBB) (posedge CLK => (QB[127] : 1'bx)) = (tcdb,tcdb,tholdb,tcdb,tholdb,tcdb);
(posedge AWT => (QA[127] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);
(posedge AWT => (QB[127] : 1'bx)) = (tawtq,tawtq,tawtqh,tawtq,tawtqh,tawtq);




if(AWT) (posedge DA[127] => (QA[127] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DA[127] => (QA[127] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge DB[127] => (QB[127] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (negedge DB[127] => (QB[127] : 1'bx)) = (tdq,tdq,tdqh,tdq,tdqh,tdq);
if(AWT) (posedge BWEBA[127] => (QA[127] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBA[127] => (QA[127] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (posedge BWEBB[127] => (QB[127] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
if(AWT) (negedge BWEBB[127] => (QB[127] : 1'bx)) = (tbwebq,tbwebq,tbwebqh,tbwebq,tbwebqh,tbwebq);
endspecify
`endif

initial begin
    assign EN = 1;
    RDA = 1;
    RDB = 1;
    ABL = 1'b1;
    AAL = {M{1'b0}};
    BWEBAL = {N{1'b1}};
    BWEBBL = {N{1'b1}};
    CEBAL = 1'b1;
    CEBBL = 1'b1;
    clk_count = 0;
    sd_mode = 0;
    invalid_aslp = 1'b0;
    invalid_bslp = 1'b0;    
    invalid_adslp = 1'b0;
    invalid_bdslp = 1'b0;   
    invalid_sdwk_dslp = 1'b0;    
end

`ifdef TSMC_INITIALIZE_MEM
initial
   begin 
`ifdef TSMC_INITIALIZE_FORMAT_BINARY
     #(INITIAL_MEM_DELAY)  $readmemb(cdeFileInit, MX.mem, 0, W-1);
`else
     #(INITIAL_MEM_DELAY)  $readmemh(cdeFileInit, MX.mem, 0, W-1);
`endif
   end
`endif //  `ifdef TSMC_INITIALIZE_MEM
   
`ifdef TSMC_INITIALIZE_FAULT
initial
   begin
`ifdef TSMC_INITIALIZE_FORMAT_BINARY
     #(INITIAL_FAULT_DELAY) $readmemb(cdeFileFault, MX.mem_fault, 0, W-1);
`else
     #(INITIAL_FAULT_DELAY) $readmemh(cdeFileFault, MX.mem_fault, 0, W-1);
`endif
   end
`endif //  `ifdef TSMC_INITIALIZE_FAULT


always @(bRTSEL) begin
    if (bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
        if(($realtime > 0) && (!CEBAL || !CEBBL) ) begin
`ifdef no_warning
`else        
            $display("\tWarning %m : input RTSEL should not be toggled when CEBA/CEBB is low at simulation time %t\n", $realtime);
`endif            
    `ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
    `endif
            bQA = {N{1'bx}};
            bQB = {N{1'bx}};
            xMemoryAll;
        end
    end
end
always @(bWTSEL) begin
    if (bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
        if(($realtime > 0) && (!CEBAL || !CEBBL) ) begin
`ifdef no_warning
`else        
            $display("\tWarning %m : input WTSEL should not be toggled when CEBA/CEBB is low at simulation time %t\n", $realtime);
`endif            
    `ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
    `endif
            bQA = {N{1'bx}};
            bQB = {N{1'bx}};
            xMemoryAll;
        end
    end
end
always @(bPTSEL) begin
    if (bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
        if(($realtime > 0) && (!CEBAL || !CEBBL) ) begin
`ifdef no_warning
`else        
            $display("\tWarning %m : input PTSEL should not be toggled when CEBA/CEBB is low at simulation time %t\n", $realtime);
`endif            
    `ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
    `endif
            bQA = {N{1'bx}};
            bQB = {N{1'bx}};
            xMemoryAll;
        end
    end
end

`ifdef TSMC_NO_TESTPINS_WARNING
`else
always @(bCLKA or bCLKB or bRTSEL) 
begin
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
        if((bRTSEL !== 2'b00) && ($realtime > 0)) 
        begin
            $display("\tError %m : input RTSEL should be set to 2'b00 at simulation time %t\n", $realtime);
            $display("\tError %m : Please refer the datasheet for the RTSEL setting in the different segment and mux configuration\n");
            bQA <= #0.01 {N{1'bx}};
            bQB <= #0.01 {N{1'bx}};
            AAL <= {M{1'bx}};
            BWEBAL <= {N{1'b0}};
        end
    end
end

always @(bCLKA or bCLKB or bWTSEL) 
begin
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
        if((bWTSEL !== 2'b00) && ($realtime > 0)) 
        begin
            $display("\tError %m : input WTSEL should be set to 2'b00 at simulation time %t\n", $realtime);
            $display("\tError %m : Please refer the datasheet for the WTSEL setting in the different segment and mux configuration\n");
            bQA <= #0.01 {N{1'bx}};
            bQB <= #0.01 {N{1'bx}};
            AAL <= {M{1'bx}};
            BWEBAL <= {N{1'b0}};
        end
    end
end

always @(bCLKA or bCLKB or bPTSEL) 
begin
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
        if((bPTSEL !== 2'b00) && ($realtime > 0)) 
        begin
            $display("\tError %m : input PTSEL should be set to 2'b00 at simulation time %t\n", $realtime);
            $display("\tError %m : Please refer the datasheet for the PTSEL setting in the different segment and mux configuration\n");
            bQA <= #0.01 {N{1'bx}};
            bQB <= #0.01 {N{1'bx}};
            AAL <= {M{1'bx}};
            BWEBAL <= {N{1'b0}};
        end
    end
end

`endif

//always @(bTMA or bTMB) begin
//    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0 && bTMA === 1'b1 && bTMB === 1'b1) begin
//        if( MES_ALL=="ON" && $realtime != 0)
//        begin
//            $display("\nWarning %m : TMA and TMB cannot both be 1 at the same time, at %t. >>", $realtime);
//        end
//        xMemoryAll;
//`ifdef TSMC_CM_UNIT_DELAY
//        bQA <= #(SRAM_DELAY + 0.001) {N{1'bx}}; 
//        bQB <= #(SRAM_DELAY + 0.001) {N{1'bx}};
//`else
//        bQA <= #0.01 {N{1'bx}}; 
//        bQB <= #0.01 {N{1'bx}};
//`endif
//    end
//end

always @(bCLKA) 
begin : CLKAOP
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0 && invalid_sdwk_dslp === 1'b0) begin
    if(bCLKA === 1'bx) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\nWarning %m : CLK unknown at %t. >>", $realtime);
        end
        xMemoryAll;
        if(bAWT === 1'b0) begin
            bQA <= #0.01 {N{1'bx}};
        end
    end
    else if(bCLKA === 1'b1 && RCLKA === 1'b0) 
    begin
        if(bCEBA === 1'bx) 
        begin
            if( MES_ALL=="ON" && $realtime != 0)
            begin
                $display("\nWarning %m CEBA unknown at %t. >>", $realtime);
            end
            xMemoryAll;
            if(bAWT === 1'b0) begin
                bQA <= #0.01 {N{1'bx}}; 
            end
        end
        else if(bWEBA === 1'bx && bCEBA === 1'b0) 
        begin
            if( MES_ALL=="ON" && $realtime != 0)
            begin
                $display("\nWarning %m WEBA unknown at %t. >>", $realtime);
            end
            xMemoryAll;
            if(bAWT === 1'b0) begin
                bQA <= #0.01 {N{1'bx}}; 
            end
        end
        else begin                                
            WEBAL = bWEBA;
            CEBAL = bCEBA;
            if(^bAA === 1'bx && bWEBA === 1'b0 && bCEBA === 1'b0) 
            begin
                if( MES_ALL=="ON" && $realtime != 0)
                begin
                    $display("\nWarning %m WRITE AA unknown at %t. >>", $realtime);
                end
                xMemoryAll;
            end
            else if(^bAA === 1'bx && bWEBA === 1'b1 && bCEBA === 1'b0) 
            begin
                if( MES_ALL=="ON" && $realtime != 0)
                begin
                    $display("\nWarning %m READ AA unknown at %t. >>", $realtime);
                end
                xMemoryAll;
                if(bAWT === 1'b0) begin
                    bQA <= #0.01 {N{1'bx}}; 
                end
            end
            else 
            begin
                if(!bCEBA) 
                begin    // begin if(bCEBA)
                    AAL = bAA;
                    DAL = bDA;
                    if(bWEBA === 1'b1 && clk_count == 0)
                    begin
                        RDA = ~RDA;
                    end
                    if(bWEBA === 1'b0) 
                    begin
                        for (i = 0; i < N; i = i + 1) 
                        begin
                            if(!bBWEBA[i] && !bWEBA) 
                            begin
                                BWEBAL[i] = 1'b0;
                            end
                            if(bWEBA === 1'bx || bBWEBA[i] === 1'bx)
                            begin
                                BWEBAL[i] = 1'b0;
                                DAL[i] = 1'bx;
                            end
                        end
                        if(^bBWEBA === 1'bx) 
                        begin
                            if( MES_ALL=="ON" && $realtime != 0)
                            begin
                                $display("\nWarning %m BWEBA unknown at %t. >>", $realtime);
                            end
                        end
                    end
                    else if(bWEBA === 1'b1 && bAWT === 1'b1) 
                    begin
                        if( MES_ALL=="ON" && $realtime != 0) 
                            $display("\nInfo %m Read operation failed during AWT mode at %t. >>", $realtime);
                    end
                end
            end
        end                                

        CEBBL = bCEBB;
        if(bCEBB === 1'b0) begin
            WEBBL = bWEBB;
            ABL   = bAB;
            bBWEBBL = bBWEBB;
            bDBL    = bDB;
        end
        #0.001;

        if(CEBBL === 1'bx) 
        begin
            if( MES_ALL=="ON" && $realtime != 0)
            begin
                $display("\nWarning %m CEBB unknown at %t. >>", $realtime);
            end
            xMemoryAll;
            if(bAWT === 1'b0) begin
                bQB <= #0.01 {N{1'bx}}; 
            end
        end
        else if(WEBBL === 1'bx && CEBBL === 1'b0) 
        begin
            if( MES_ALL=="ON" && $realtime != 0)
            begin
                $display("\nWarning %m WEBB unknown at %t. >>", $realtime);
            end
            xMemoryAll;
            if(bAWT === 1'b0) begin
                bQB <= #0.01 {N{1'bx}}; 
            end
        end
        else 
        begin                               
            if(^ABL === 1'bx && WEBBL === 1'b0 && CEBBL === 1'b0) 
            begin
                if( MES_ALL=="ON" && $realtime != 0)
                begin
                    $display("\nWarning %m WRITE AB unknown at %t. >>", $realtime);
                end
                xMemoryAll;
            end
            else if(^ABL === 1'bx && WEBBL === 1'b1 && CEBBL === 1'b0) 
            begin
                if( MES_ALL=="ON" && $realtime != 0)
                begin
                    $display("\nWarning %m READ AB unknown at %t. >>", $realtime);
                end
                xMemoryAll;
                if(bAWT === 1'b0) begin
                    bQB <= #0.01 {N{1'bx}}; 
                end
            end
            else begin
                if(!CEBBL) 
                begin    // begin if(CEBBL)
                    DBL = bDBL;                    
                    if(WEBBL === 1'b1 && clk_count == 0)
                    begin
                        RDB = ~RDB;
                    end
                    if(WEBBL !== 1'b1) 
                    begin
                        for (i = 0; i < N; i = i + 1) 
                        begin
                            if(!bBWEBBL[i] && !WEBBL) 
                            begin
                                BWEBBL[i] = 1'b0;
                            end
                            if(WEBBL === 1'bx || bBWEBBL[i] === 1'bx)
                            begin
                                BWEBBL[i] = 1'b0;
                                DBL[i] = 1'bx;
                            end
                        end
                        if(^bBWEBBL === 1'bx) 
                        begin
                            if( MES_ALL=="ON" && $realtime != 0)
                            begin
                                $display("\nWarning %m BWEBB unknown at %t. >>", $realtime);
                            end
                        end
                    end
                    else if(WEBBL === 1'b1 && bAWT === 1'b1) 
                    begin
                        if( MES_ALL=="ON" && $realtime != 0) 
                            $display("\nInfo %m Read operation failed during AWT mode at %t. >>", $realtime);
                    end
                end
            end
        end                       
    end
    end
    #0.001 RCLKA = bCLKA;

end

always @(bAWT or bDA[0] or bBWEBA[0]) begin : AWTQA0
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[0] = 1'bx; 
        #0.01;
       `endif
        bQA[0] = bDA[0] ^ bBWEBA[0];
    end
    end
end
always @(bAWT or bDB[0] or bBWEBB[0]) begin : AWTQB0
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[0] = 1'bx;
        #0.01;
        `endif
        bQB[0] = bDB[0] ^ bBWEBB[0];
    end
    end
end
always @(bAWT or bDA[1] or bBWEBA[1]) begin : AWTQA1
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[1] = 1'bx; 
        #0.01;
       `endif
        bQA[1] = bDA[1] ^ bBWEBA[1];
    end
    end
end
always @(bAWT or bDB[1] or bBWEBB[1]) begin : AWTQB1
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[1] = 1'bx;
        #0.01;
        `endif
        bQB[1] = bDB[1] ^ bBWEBB[1];
    end
    end
end
always @(bAWT or bDA[2] or bBWEBA[2]) begin : AWTQA2
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[2] = 1'bx; 
        #0.01;
       `endif
        bQA[2] = bDA[2] ^ bBWEBA[2];
    end
    end
end
always @(bAWT or bDB[2] or bBWEBB[2]) begin : AWTQB2
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[2] = 1'bx;
        #0.01;
        `endif
        bQB[2] = bDB[2] ^ bBWEBB[2];
    end
    end
end
always @(bAWT or bDA[3] or bBWEBA[3]) begin : AWTQA3
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[3] = 1'bx; 
        #0.01;
       `endif
        bQA[3] = bDA[3] ^ bBWEBA[3];
    end
    end
end
always @(bAWT or bDB[3] or bBWEBB[3]) begin : AWTQB3
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[3] = 1'bx;
        #0.01;
        `endif
        bQB[3] = bDB[3] ^ bBWEBB[3];
    end
    end
end
always @(bAWT or bDA[4] or bBWEBA[4]) begin : AWTQA4
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[4] = 1'bx; 
        #0.01;
       `endif
        bQA[4] = bDA[4] ^ bBWEBA[4];
    end
    end
end
always @(bAWT or bDB[4] or bBWEBB[4]) begin : AWTQB4
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[4] = 1'bx;
        #0.01;
        `endif
        bQB[4] = bDB[4] ^ bBWEBB[4];
    end
    end
end
always @(bAWT or bDA[5] or bBWEBA[5]) begin : AWTQA5
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[5] = 1'bx; 
        #0.01;
       `endif
        bQA[5] = bDA[5] ^ bBWEBA[5];
    end
    end
end
always @(bAWT or bDB[5] or bBWEBB[5]) begin : AWTQB5
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[5] = 1'bx;
        #0.01;
        `endif
        bQB[5] = bDB[5] ^ bBWEBB[5];
    end
    end
end
always @(bAWT or bDA[6] or bBWEBA[6]) begin : AWTQA6
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[6] = 1'bx; 
        #0.01;
       `endif
        bQA[6] = bDA[6] ^ bBWEBA[6];
    end
    end
end
always @(bAWT or bDB[6] or bBWEBB[6]) begin : AWTQB6
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[6] = 1'bx;
        #0.01;
        `endif
        bQB[6] = bDB[6] ^ bBWEBB[6];
    end
    end
end
always @(bAWT or bDA[7] or bBWEBA[7]) begin : AWTQA7
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[7] = 1'bx; 
        #0.01;
       `endif
        bQA[7] = bDA[7] ^ bBWEBA[7];
    end
    end
end
always @(bAWT or bDB[7] or bBWEBB[7]) begin : AWTQB7
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[7] = 1'bx;
        #0.01;
        `endif
        bQB[7] = bDB[7] ^ bBWEBB[7];
    end
    end
end
always @(bAWT or bDA[8] or bBWEBA[8]) begin : AWTQA8
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[8] = 1'bx; 
        #0.01;
       `endif
        bQA[8] = bDA[8] ^ bBWEBA[8];
    end
    end
end
always @(bAWT or bDB[8] or bBWEBB[8]) begin : AWTQB8
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[8] = 1'bx;
        #0.01;
        `endif
        bQB[8] = bDB[8] ^ bBWEBB[8];
    end
    end
end
always @(bAWT or bDA[9] or bBWEBA[9]) begin : AWTQA9
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[9] = 1'bx; 
        #0.01;
       `endif
        bQA[9] = bDA[9] ^ bBWEBA[9];
    end
    end
end
always @(bAWT or bDB[9] or bBWEBB[9]) begin : AWTQB9
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[9] = 1'bx;
        #0.01;
        `endif
        bQB[9] = bDB[9] ^ bBWEBB[9];
    end
    end
end
always @(bAWT or bDA[10] or bBWEBA[10]) begin : AWTQA10
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[10] = 1'bx; 
        #0.01;
       `endif
        bQA[10] = bDA[10] ^ bBWEBA[10];
    end
    end
end
always @(bAWT or bDB[10] or bBWEBB[10]) begin : AWTQB10
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[10] = 1'bx;
        #0.01;
        `endif
        bQB[10] = bDB[10] ^ bBWEBB[10];
    end
    end
end
always @(bAWT or bDA[11] or bBWEBA[11]) begin : AWTQA11
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[11] = 1'bx; 
        #0.01;
       `endif
        bQA[11] = bDA[11] ^ bBWEBA[11];
    end
    end
end
always @(bAWT or bDB[11] or bBWEBB[11]) begin : AWTQB11
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[11] = 1'bx;
        #0.01;
        `endif
        bQB[11] = bDB[11] ^ bBWEBB[11];
    end
    end
end
always @(bAWT or bDA[12] or bBWEBA[12]) begin : AWTQA12
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[12] = 1'bx; 
        #0.01;
       `endif
        bQA[12] = bDA[12] ^ bBWEBA[12];
    end
    end
end
always @(bAWT or bDB[12] or bBWEBB[12]) begin : AWTQB12
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[12] = 1'bx;
        #0.01;
        `endif
        bQB[12] = bDB[12] ^ bBWEBB[12];
    end
    end
end
always @(bAWT or bDA[13] or bBWEBA[13]) begin : AWTQA13
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[13] = 1'bx; 
        #0.01;
       `endif
        bQA[13] = bDA[13] ^ bBWEBA[13];
    end
    end
end
always @(bAWT or bDB[13] or bBWEBB[13]) begin : AWTQB13
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[13] = 1'bx;
        #0.01;
        `endif
        bQB[13] = bDB[13] ^ bBWEBB[13];
    end
    end
end
always @(bAWT or bDA[14] or bBWEBA[14]) begin : AWTQA14
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[14] = 1'bx; 
        #0.01;
       `endif
        bQA[14] = bDA[14] ^ bBWEBA[14];
    end
    end
end
always @(bAWT or bDB[14] or bBWEBB[14]) begin : AWTQB14
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[14] = 1'bx;
        #0.01;
        `endif
        bQB[14] = bDB[14] ^ bBWEBB[14];
    end
    end
end
always @(bAWT or bDA[15] or bBWEBA[15]) begin : AWTQA15
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[15] = 1'bx; 
        #0.01;
       `endif
        bQA[15] = bDA[15] ^ bBWEBA[15];
    end
    end
end
always @(bAWT or bDB[15] or bBWEBB[15]) begin : AWTQB15
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[15] = 1'bx;
        #0.01;
        `endif
        bQB[15] = bDB[15] ^ bBWEBB[15];
    end
    end
end
always @(bAWT or bDA[16] or bBWEBA[16]) begin : AWTQA16
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[16] = 1'bx; 
        #0.01;
       `endif
        bQA[16] = bDA[16] ^ bBWEBA[16];
    end
    end
end
always @(bAWT or bDB[16] or bBWEBB[16]) begin : AWTQB16
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[16] = 1'bx;
        #0.01;
        `endif
        bQB[16] = bDB[16] ^ bBWEBB[16];
    end
    end
end
always @(bAWT or bDA[17] or bBWEBA[17]) begin : AWTQA17
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[17] = 1'bx; 
        #0.01;
       `endif
        bQA[17] = bDA[17] ^ bBWEBA[17];
    end
    end
end
always @(bAWT or bDB[17] or bBWEBB[17]) begin : AWTQB17
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[17] = 1'bx;
        #0.01;
        `endif
        bQB[17] = bDB[17] ^ bBWEBB[17];
    end
    end
end
always @(bAWT or bDA[18] or bBWEBA[18]) begin : AWTQA18
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[18] = 1'bx; 
        #0.01;
       `endif
        bQA[18] = bDA[18] ^ bBWEBA[18];
    end
    end
end
always @(bAWT or bDB[18] or bBWEBB[18]) begin : AWTQB18
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[18] = 1'bx;
        #0.01;
        `endif
        bQB[18] = bDB[18] ^ bBWEBB[18];
    end
    end
end
always @(bAWT or bDA[19] or bBWEBA[19]) begin : AWTQA19
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[19] = 1'bx; 
        #0.01;
       `endif
        bQA[19] = bDA[19] ^ bBWEBA[19];
    end
    end
end
always @(bAWT or bDB[19] or bBWEBB[19]) begin : AWTQB19
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[19] = 1'bx;
        #0.01;
        `endif
        bQB[19] = bDB[19] ^ bBWEBB[19];
    end
    end
end
always @(bAWT or bDA[20] or bBWEBA[20]) begin : AWTQA20
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[20] = 1'bx; 
        #0.01;
       `endif
        bQA[20] = bDA[20] ^ bBWEBA[20];
    end
    end
end
always @(bAWT or bDB[20] or bBWEBB[20]) begin : AWTQB20
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[20] = 1'bx;
        #0.01;
        `endif
        bQB[20] = bDB[20] ^ bBWEBB[20];
    end
    end
end
always @(bAWT or bDA[21] or bBWEBA[21]) begin : AWTQA21
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[21] = 1'bx; 
        #0.01;
       `endif
        bQA[21] = bDA[21] ^ bBWEBA[21];
    end
    end
end
always @(bAWT or bDB[21] or bBWEBB[21]) begin : AWTQB21
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[21] = 1'bx;
        #0.01;
        `endif
        bQB[21] = bDB[21] ^ bBWEBB[21];
    end
    end
end
always @(bAWT or bDA[22] or bBWEBA[22]) begin : AWTQA22
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[22] = 1'bx; 
        #0.01;
       `endif
        bQA[22] = bDA[22] ^ bBWEBA[22];
    end
    end
end
always @(bAWT or bDB[22] or bBWEBB[22]) begin : AWTQB22
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[22] = 1'bx;
        #0.01;
        `endif
        bQB[22] = bDB[22] ^ bBWEBB[22];
    end
    end
end
always @(bAWT or bDA[23] or bBWEBA[23]) begin : AWTQA23
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[23] = 1'bx; 
        #0.01;
       `endif
        bQA[23] = bDA[23] ^ bBWEBA[23];
    end
    end
end
always @(bAWT or bDB[23] or bBWEBB[23]) begin : AWTQB23
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[23] = 1'bx;
        #0.01;
        `endif
        bQB[23] = bDB[23] ^ bBWEBB[23];
    end
    end
end
always @(bAWT or bDA[24] or bBWEBA[24]) begin : AWTQA24
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[24] = 1'bx; 
        #0.01;
       `endif
        bQA[24] = bDA[24] ^ bBWEBA[24];
    end
    end
end
always @(bAWT or bDB[24] or bBWEBB[24]) begin : AWTQB24
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[24] = 1'bx;
        #0.01;
        `endif
        bQB[24] = bDB[24] ^ bBWEBB[24];
    end
    end
end
always @(bAWT or bDA[25] or bBWEBA[25]) begin : AWTQA25
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[25] = 1'bx; 
        #0.01;
       `endif
        bQA[25] = bDA[25] ^ bBWEBA[25];
    end
    end
end
always @(bAWT or bDB[25] or bBWEBB[25]) begin : AWTQB25
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[25] = 1'bx;
        #0.01;
        `endif
        bQB[25] = bDB[25] ^ bBWEBB[25];
    end
    end
end
always @(bAWT or bDA[26] or bBWEBA[26]) begin : AWTQA26
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[26] = 1'bx; 
        #0.01;
       `endif
        bQA[26] = bDA[26] ^ bBWEBA[26];
    end
    end
end
always @(bAWT or bDB[26] or bBWEBB[26]) begin : AWTQB26
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[26] = 1'bx;
        #0.01;
        `endif
        bQB[26] = bDB[26] ^ bBWEBB[26];
    end
    end
end
always @(bAWT or bDA[27] or bBWEBA[27]) begin : AWTQA27
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[27] = 1'bx; 
        #0.01;
       `endif
        bQA[27] = bDA[27] ^ bBWEBA[27];
    end
    end
end
always @(bAWT or bDB[27] or bBWEBB[27]) begin : AWTQB27
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[27] = 1'bx;
        #0.01;
        `endif
        bQB[27] = bDB[27] ^ bBWEBB[27];
    end
    end
end
always @(bAWT or bDA[28] or bBWEBA[28]) begin : AWTQA28
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[28] = 1'bx; 
        #0.01;
       `endif
        bQA[28] = bDA[28] ^ bBWEBA[28];
    end
    end
end
always @(bAWT or bDB[28] or bBWEBB[28]) begin : AWTQB28
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[28] = 1'bx;
        #0.01;
        `endif
        bQB[28] = bDB[28] ^ bBWEBB[28];
    end
    end
end
always @(bAWT or bDA[29] or bBWEBA[29]) begin : AWTQA29
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[29] = 1'bx; 
        #0.01;
       `endif
        bQA[29] = bDA[29] ^ bBWEBA[29];
    end
    end
end
always @(bAWT or bDB[29] or bBWEBB[29]) begin : AWTQB29
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[29] = 1'bx;
        #0.01;
        `endif
        bQB[29] = bDB[29] ^ bBWEBB[29];
    end
    end
end
always @(bAWT or bDA[30] or bBWEBA[30]) begin : AWTQA30
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[30] = 1'bx; 
        #0.01;
       `endif
        bQA[30] = bDA[30] ^ bBWEBA[30];
    end
    end
end
always @(bAWT or bDB[30] or bBWEBB[30]) begin : AWTQB30
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[30] = 1'bx;
        #0.01;
        `endif
        bQB[30] = bDB[30] ^ bBWEBB[30];
    end
    end
end
always @(bAWT or bDA[31] or bBWEBA[31]) begin : AWTQA31
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[31] = 1'bx; 
        #0.01;
       `endif
        bQA[31] = bDA[31] ^ bBWEBA[31];
    end
    end
end
always @(bAWT or bDB[31] or bBWEBB[31]) begin : AWTQB31
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[31] = 1'bx;
        #0.01;
        `endif
        bQB[31] = bDB[31] ^ bBWEBB[31];
    end
    end
end
always @(bAWT or bDA[32] or bBWEBA[32]) begin : AWTQA32
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[32] = 1'bx; 
        #0.01;
       `endif
        bQA[32] = bDA[32] ^ bBWEBA[32];
    end
    end
end
always @(bAWT or bDB[32] or bBWEBB[32]) begin : AWTQB32
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[32] = 1'bx;
        #0.01;
        `endif
        bQB[32] = bDB[32] ^ bBWEBB[32];
    end
    end
end
always @(bAWT or bDA[33] or bBWEBA[33]) begin : AWTQA33
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[33] = 1'bx; 
        #0.01;
       `endif
        bQA[33] = bDA[33] ^ bBWEBA[33];
    end
    end
end
always @(bAWT or bDB[33] or bBWEBB[33]) begin : AWTQB33
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[33] = 1'bx;
        #0.01;
        `endif
        bQB[33] = bDB[33] ^ bBWEBB[33];
    end
    end
end
always @(bAWT or bDA[34] or bBWEBA[34]) begin : AWTQA34
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[34] = 1'bx; 
        #0.01;
       `endif
        bQA[34] = bDA[34] ^ bBWEBA[34];
    end
    end
end
always @(bAWT or bDB[34] or bBWEBB[34]) begin : AWTQB34
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[34] = 1'bx;
        #0.01;
        `endif
        bQB[34] = bDB[34] ^ bBWEBB[34];
    end
    end
end
always @(bAWT or bDA[35] or bBWEBA[35]) begin : AWTQA35
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[35] = 1'bx; 
        #0.01;
       `endif
        bQA[35] = bDA[35] ^ bBWEBA[35];
    end
    end
end
always @(bAWT or bDB[35] or bBWEBB[35]) begin : AWTQB35
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[35] = 1'bx;
        #0.01;
        `endif
        bQB[35] = bDB[35] ^ bBWEBB[35];
    end
    end
end
always @(bAWT or bDA[36] or bBWEBA[36]) begin : AWTQA36
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[36] = 1'bx; 
        #0.01;
       `endif
        bQA[36] = bDA[36] ^ bBWEBA[36];
    end
    end
end
always @(bAWT or bDB[36] or bBWEBB[36]) begin : AWTQB36
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[36] = 1'bx;
        #0.01;
        `endif
        bQB[36] = bDB[36] ^ bBWEBB[36];
    end
    end
end
always @(bAWT or bDA[37] or bBWEBA[37]) begin : AWTQA37
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[37] = 1'bx; 
        #0.01;
       `endif
        bQA[37] = bDA[37] ^ bBWEBA[37];
    end
    end
end
always @(bAWT or bDB[37] or bBWEBB[37]) begin : AWTQB37
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[37] = 1'bx;
        #0.01;
        `endif
        bQB[37] = bDB[37] ^ bBWEBB[37];
    end
    end
end
always @(bAWT or bDA[38] or bBWEBA[38]) begin : AWTQA38
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[38] = 1'bx; 
        #0.01;
       `endif
        bQA[38] = bDA[38] ^ bBWEBA[38];
    end
    end
end
always @(bAWT or bDB[38] or bBWEBB[38]) begin : AWTQB38
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[38] = 1'bx;
        #0.01;
        `endif
        bQB[38] = bDB[38] ^ bBWEBB[38];
    end
    end
end
always @(bAWT or bDA[39] or bBWEBA[39]) begin : AWTQA39
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[39] = 1'bx; 
        #0.01;
       `endif
        bQA[39] = bDA[39] ^ bBWEBA[39];
    end
    end
end
always @(bAWT or bDB[39] or bBWEBB[39]) begin : AWTQB39
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[39] = 1'bx;
        #0.01;
        `endif
        bQB[39] = bDB[39] ^ bBWEBB[39];
    end
    end
end
always @(bAWT or bDA[40] or bBWEBA[40]) begin : AWTQA40
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[40] = 1'bx; 
        #0.01;
       `endif
        bQA[40] = bDA[40] ^ bBWEBA[40];
    end
    end
end
always @(bAWT or bDB[40] or bBWEBB[40]) begin : AWTQB40
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[40] = 1'bx;
        #0.01;
        `endif
        bQB[40] = bDB[40] ^ bBWEBB[40];
    end
    end
end
always @(bAWT or bDA[41] or bBWEBA[41]) begin : AWTQA41
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[41] = 1'bx; 
        #0.01;
       `endif
        bQA[41] = bDA[41] ^ bBWEBA[41];
    end
    end
end
always @(bAWT or bDB[41] or bBWEBB[41]) begin : AWTQB41
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[41] = 1'bx;
        #0.01;
        `endif
        bQB[41] = bDB[41] ^ bBWEBB[41];
    end
    end
end
always @(bAWT or bDA[42] or bBWEBA[42]) begin : AWTQA42
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[42] = 1'bx; 
        #0.01;
       `endif
        bQA[42] = bDA[42] ^ bBWEBA[42];
    end
    end
end
always @(bAWT or bDB[42] or bBWEBB[42]) begin : AWTQB42
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[42] = 1'bx;
        #0.01;
        `endif
        bQB[42] = bDB[42] ^ bBWEBB[42];
    end
    end
end
always @(bAWT or bDA[43] or bBWEBA[43]) begin : AWTQA43
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[43] = 1'bx; 
        #0.01;
       `endif
        bQA[43] = bDA[43] ^ bBWEBA[43];
    end
    end
end
always @(bAWT or bDB[43] or bBWEBB[43]) begin : AWTQB43
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[43] = 1'bx;
        #0.01;
        `endif
        bQB[43] = bDB[43] ^ bBWEBB[43];
    end
    end
end
always @(bAWT or bDA[44] or bBWEBA[44]) begin : AWTQA44
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[44] = 1'bx; 
        #0.01;
       `endif
        bQA[44] = bDA[44] ^ bBWEBA[44];
    end
    end
end
always @(bAWT or bDB[44] or bBWEBB[44]) begin : AWTQB44
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[44] = 1'bx;
        #0.01;
        `endif
        bQB[44] = bDB[44] ^ bBWEBB[44];
    end
    end
end
always @(bAWT or bDA[45] or bBWEBA[45]) begin : AWTQA45
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[45] = 1'bx; 
        #0.01;
       `endif
        bQA[45] = bDA[45] ^ bBWEBA[45];
    end
    end
end
always @(bAWT or bDB[45] or bBWEBB[45]) begin : AWTQB45
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[45] = 1'bx;
        #0.01;
        `endif
        bQB[45] = bDB[45] ^ bBWEBB[45];
    end
    end
end
always @(bAWT or bDA[46] or bBWEBA[46]) begin : AWTQA46
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[46] = 1'bx; 
        #0.01;
       `endif
        bQA[46] = bDA[46] ^ bBWEBA[46];
    end
    end
end
always @(bAWT or bDB[46] or bBWEBB[46]) begin : AWTQB46
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[46] = 1'bx;
        #0.01;
        `endif
        bQB[46] = bDB[46] ^ bBWEBB[46];
    end
    end
end
always @(bAWT or bDA[47] or bBWEBA[47]) begin : AWTQA47
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[47] = 1'bx; 
        #0.01;
       `endif
        bQA[47] = bDA[47] ^ bBWEBA[47];
    end
    end
end
always @(bAWT or bDB[47] or bBWEBB[47]) begin : AWTQB47
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[47] = 1'bx;
        #0.01;
        `endif
        bQB[47] = bDB[47] ^ bBWEBB[47];
    end
    end
end
always @(bAWT or bDA[48] or bBWEBA[48]) begin : AWTQA48
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[48] = 1'bx; 
        #0.01;
       `endif
        bQA[48] = bDA[48] ^ bBWEBA[48];
    end
    end
end
always @(bAWT or bDB[48] or bBWEBB[48]) begin : AWTQB48
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[48] = 1'bx;
        #0.01;
        `endif
        bQB[48] = bDB[48] ^ bBWEBB[48];
    end
    end
end
always @(bAWT or bDA[49] or bBWEBA[49]) begin : AWTQA49
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[49] = 1'bx; 
        #0.01;
       `endif
        bQA[49] = bDA[49] ^ bBWEBA[49];
    end
    end
end
always @(bAWT or bDB[49] or bBWEBB[49]) begin : AWTQB49
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[49] = 1'bx;
        #0.01;
        `endif
        bQB[49] = bDB[49] ^ bBWEBB[49];
    end
    end
end
always @(bAWT or bDA[50] or bBWEBA[50]) begin : AWTQA50
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[50] = 1'bx; 
        #0.01;
       `endif
        bQA[50] = bDA[50] ^ bBWEBA[50];
    end
    end
end
always @(bAWT or bDB[50] or bBWEBB[50]) begin : AWTQB50
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[50] = 1'bx;
        #0.01;
        `endif
        bQB[50] = bDB[50] ^ bBWEBB[50];
    end
    end
end
always @(bAWT or bDA[51] or bBWEBA[51]) begin : AWTQA51
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[51] = 1'bx; 
        #0.01;
       `endif
        bQA[51] = bDA[51] ^ bBWEBA[51];
    end
    end
end
always @(bAWT or bDB[51] or bBWEBB[51]) begin : AWTQB51
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[51] = 1'bx;
        #0.01;
        `endif
        bQB[51] = bDB[51] ^ bBWEBB[51];
    end
    end
end
always @(bAWT or bDA[52] or bBWEBA[52]) begin : AWTQA52
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[52] = 1'bx; 
        #0.01;
       `endif
        bQA[52] = bDA[52] ^ bBWEBA[52];
    end
    end
end
always @(bAWT or bDB[52] or bBWEBB[52]) begin : AWTQB52
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[52] = 1'bx;
        #0.01;
        `endif
        bQB[52] = bDB[52] ^ bBWEBB[52];
    end
    end
end
always @(bAWT or bDA[53] or bBWEBA[53]) begin : AWTQA53
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[53] = 1'bx; 
        #0.01;
       `endif
        bQA[53] = bDA[53] ^ bBWEBA[53];
    end
    end
end
always @(bAWT or bDB[53] or bBWEBB[53]) begin : AWTQB53
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[53] = 1'bx;
        #0.01;
        `endif
        bQB[53] = bDB[53] ^ bBWEBB[53];
    end
    end
end
always @(bAWT or bDA[54] or bBWEBA[54]) begin : AWTQA54
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[54] = 1'bx; 
        #0.01;
       `endif
        bQA[54] = bDA[54] ^ bBWEBA[54];
    end
    end
end
always @(bAWT or bDB[54] or bBWEBB[54]) begin : AWTQB54
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[54] = 1'bx;
        #0.01;
        `endif
        bQB[54] = bDB[54] ^ bBWEBB[54];
    end
    end
end
always @(bAWT or bDA[55] or bBWEBA[55]) begin : AWTQA55
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[55] = 1'bx; 
        #0.01;
       `endif
        bQA[55] = bDA[55] ^ bBWEBA[55];
    end
    end
end
always @(bAWT or bDB[55] or bBWEBB[55]) begin : AWTQB55
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[55] = 1'bx;
        #0.01;
        `endif
        bQB[55] = bDB[55] ^ bBWEBB[55];
    end
    end
end
always @(bAWT or bDA[56] or bBWEBA[56]) begin : AWTQA56
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[56] = 1'bx; 
        #0.01;
       `endif
        bQA[56] = bDA[56] ^ bBWEBA[56];
    end
    end
end
always @(bAWT or bDB[56] or bBWEBB[56]) begin : AWTQB56
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[56] = 1'bx;
        #0.01;
        `endif
        bQB[56] = bDB[56] ^ bBWEBB[56];
    end
    end
end
always @(bAWT or bDA[57] or bBWEBA[57]) begin : AWTQA57
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[57] = 1'bx; 
        #0.01;
       `endif
        bQA[57] = bDA[57] ^ bBWEBA[57];
    end
    end
end
always @(bAWT or bDB[57] or bBWEBB[57]) begin : AWTQB57
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[57] = 1'bx;
        #0.01;
        `endif
        bQB[57] = bDB[57] ^ bBWEBB[57];
    end
    end
end
always @(bAWT or bDA[58] or bBWEBA[58]) begin : AWTQA58
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[58] = 1'bx; 
        #0.01;
       `endif
        bQA[58] = bDA[58] ^ bBWEBA[58];
    end
    end
end
always @(bAWT or bDB[58] or bBWEBB[58]) begin : AWTQB58
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[58] = 1'bx;
        #0.01;
        `endif
        bQB[58] = bDB[58] ^ bBWEBB[58];
    end
    end
end
always @(bAWT or bDA[59] or bBWEBA[59]) begin : AWTQA59
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[59] = 1'bx; 
        #0.01;
       `endif
        bQA[59] = bDA[59] ^ bBWEBA[59];
    end
    end
end
always @(bAWT or bDB[59] or bBWEBB[59]) begin : AWTQB59
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[59] = 1'bx;
        #0.01;
        `endif
        bQB[59] = bDB[59] ^ bBWEBB[59];
    end
    end
end
always @(bAWT or bDA[60] or bBWEBA[60]) begin : AWTQA60
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[60] = 1'bx; 
        #0.01;
       `endif
        bQA[60] = bDA[60] ^ bBWEBA[60];
    end
    end
end
always @(bAWT or bDB[60] or bBWEBB[60]) begin : AWTQB60
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[60] = 1'bx;
        #0.01;
        `endif
        bQB[60] = bDB[60] ^ bBWEBB[60];
    end
    end
end
always @(bAWT or bDA[61] or bBWEBA[61]) begin : AWTQA61
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[61] = 1'bx; 
        #0.01;
       `endif
        bQA[61] = bDA[61] ^ bBWEBA[61];
    end
    end
end
always @(bAWT or bDB[61] or bBWEBB[61]) begin : AWTQB61
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[61] = 1'bx;
        #0.01;
        `endif
        bQB[61] = bDB[61] ^ bBWEBB[61];
    end
    end
end
always @(bAWT or bDA[62] or bBWEBA[62]) begin : AWTQA62
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[62] = 1'bx; 
        #0.01;
       `endif
        bQA[62] = bDA[62] ^ bBWEBA[62];
    end
    end
end
always @(bAWT or bDB[62] or bBWEBB[62]) begin : AWTQB62
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[62] = 1'bx;
        #0.01;
        `endif
        bQB[62] = bDB[62] ^ bBWEBB[62];
    end
    end
end
always @(bAWT or bDA[63] or bBWEBA[63]) begin : AWTQA63
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[63] = 1'bx; 
        #0.01;
       `endif
        bQA[63] = bDA[63] ^ bBWEBA[63];
    end
    end
end
always @(bAWT or bDB[63] or bBWEBB[63]) begin : AWTQB63
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[63] = 1'bx;
        #0.01;
        `endif
        bQB[63] = bDB[63] ^ bBWEBB[63];
    end
    end
end
always @(bAWT or bDA[64] or bBWEBA[64]) begin : AWTQA64
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[64] = 1'bx; 
        #0.01;
       `endif
        bQA[64] = bDA[64] ^ bBWEBA[64];
    end
    end
end
always @(bAWT or bDB[64] or bBWEBB[64]) begin : AWTQB64
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[64] = 1'bx;
        #0.01;
        `endif
        bQB[64] = bDB[64] ^ bBWEBB[64];
    end
    end
end
always @(bAWT or bDA[65] or bBWEBA[65]) begin : AWTQA65
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[65] = 1'bx; 
        #0.01;
       `endif
        bQA[65] = bDA[65] ^ bBWEBA[65];
    end
    end
end
always @(bAWT or bDB[65] or bBWEBB[65]) begin : AWTQB65
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[65] = 1'bx;
        #0.01;
        `endif
        bQB[65] = bDB[65] ^ bBWEBB[65];
    end
    end
end
always @(bAWT or bDA[66] or bBWEBA[66]) begin : AWTQA66
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[66] = 1'bx; 
        #0.01;
       `endif
        bQA[66] = bDA[66] ^ bBWEBA[66];
    end
    end
end
always @(bAWT or bDB[66] or bBWEBB[66]) begin : AWTQB66
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[66] = 1'bx;
        #0.01;
        `endif
        bQB[66] = bDB[66] ^ bBWEBB[66];
    end
    end
end
always @(bAWT or bDA[67] or bBWEBA[67]) begin : AWTQA67
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[67] = 1'bx; 
        #0.01;
       `endif
        bQA[67] = bDA[67] ^ bBWEBA[67];
    end
    end
end
always @(bAWT or bDB[67] or bBWEBB[67]) begin : AWTQB67
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[67] = 1'bx;
        #0.01;
        `endif
        bQB[67] = bDB[67] ^ bBWEBB[67];
    end
    end
end
always @(bAWT or bDA[68] or bBWEBA[68]) begin : AWTQA68
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[68] = 1'bx; 
        #0.01;
       `endif
        bQA[68] = bDA[68] ^ bBWEBA[68];
    end
    end
end
always @(bAWT or bDB[68] or bBWEBB[68]) begin : AWTQB68
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[68] = 1'bx;
        #0.01;
        `endif
        bQB[68] = bDB[68] ^ bBWEBB[68];
    end
    end
end
always @(bAWT or bDA[69] or bBWEBA[69]) begin : AWTQA69
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[69] = 1'bx; 
        #0.01;
       `endif
        bQA[69] = bDA[69] ^ bBWEBA[69];
    end
    end
end
always @(bAWT or bDB[69] or bBWEBB[69]) begin : AWTQB69
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[69] = 1'bx;
        #0.01;
        `endif
        bQB[69] = bDB[69] ^ bBWEBB[69];
    end
    end
end
always @(bAWT or bDA[70] or bBWEBA[70]) begin : AWTQA70
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[70] = 1'bx; 
        #0.01;
       `endif
        bQA[70] = bDA[70] ^ bBWEBA[70];
    end
    end
end
always @(bAWT or bDB[70] or bBWEBB[70]) begin : AWTQB70
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[70] = 1'bx;
        #0.01;
        `endif
        bQB[70] = bDB[70] ^ bBWEBB[70];
    end
    end
end
always @(bAWT or bDA[71] or bBWEBA[71]) begin : AWTQA71
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[71] = 1'bx; 
        #0.01;
       `endif
        bQA[71] = bDA[71] ^ bBWEBA[71];
    end
    end
end
always @(bAWT or bDB[71] or bBWEBB[71]) begin : AWTQB71
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[71] = 1'bx;
        #0.01;
        `endif
        bQB[71] = bDB[71] ^ bBWEBB[71];
    end
    end
end
always @(bAWT or bDA[72] or bBWEBA[72]) begin : AWTQA72
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[72] = 1'bx; 
        #0.01;
       `endif
        bQA[72] = bDA[72] ^ bBWEBA[72];
    end
    end
end
always @(bAWT or bDB[72] or bBWEBB[72]) begin : AWTQB72
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[72] = 1'bx;
        #0.01;
        `endif
        bQB[72] = bDB[72] ^ bBWEBB[72];
    end
    end
end
always @(bAWT or bDA[73] or bBWEBA[73]) begin : AWTQA73
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[73] = 1'bx; 
        #0.01;
       `endif
        bQA[73] = bDA[73] ^ bBWEBA[73];
    end
    end
end
always @(bAWT or bDB[73] or bBWEBB[73]) begin : AWTQB73
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[73] = 1'bx;
        #0.01;
        `endif
        bQB[73] = bDB[73] ^ bBWEBB[73];
    end
    end
end
always @(bAWT or bDA[74] or bBWEBA[74]) begin : AWTQA74
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[74] = 1'bx; 
        #0.01;
       `endif
        bQA[74] = bDA[74] ^ bBWEBA[74];
    end
    end
end
always @(bAWT or bDB[74] or bBWEBB[74]) begin : AWTQB74
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[74] = 1'bx;
        #0.01;
        `endif
        bQB[74] = bDB[74] ^ bBWEBB[74];
    end
    end
end
always @(bAWT or bDA[75] or bBWEBA[75]) begin : AWTQA75
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[75] = 1'bx; 
        #0.01;
       `endif
        bQA[75] = bDA[75] ^ bBWEBA[75];
    end
    end
end
always @(bAWT or bDB[75] or bBWEBB[75]) begin : AWTQB75
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[75] = 1'bx;
        #0.01;
        `endif
        bQB[75] = bDB[75] ^ bBWEBB[75];
    end
    end
end
always @(bAWT or bDA[76] or bBWEBA[76]) begin : AWTQA76
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[76] = 1'bx; 
        #0.01;
       `endif
        bQA[76] = bDA[76] ^ bBWEBA[76];
    end
    end
end
always @(bAWT or bDB[76] or bBWEBB[76]) begin : AWTQB76
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[76] = 1'bx;
        #0.01;
        `endif
        bQB[76] = bDB[76] ^ bBWEBB[76];
    end
    end
end
always @(bAWT or bDA[77] or bBWEBA[77]) begin : AWTQA77
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[77] = 1'bx; 
        #0.01;
       `endif
        bQA[77] = bDA[77] ^ bBWEBA[77];
    end
    end
end
always @(bAWT or bDB[77] or bBWEBB[77]) begin : AWTQB77
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[77] = 1'bx;
        #0.01;
        `endif
        bQB[77] = bDB[77] ^ bBWEBB[77];
    end
    end
end
always @(bAWT or bDA[78] or bBWEBA[78]) begin : AWTQA78
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[78] = 1'bx; 
        #0.01;
       `endif
        bQA[78] = bDA[78] ^ bBWEBA[78];
    end
    end
end
always @(bAWT or bDB[78] or bBWEBB[78]) begin : AWTQB78
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[78] = 1'bx;
        #0.01;
        `endif
        bQB[78] = bDB[78] ^ bBWEBB[78];
    end
    end
end
always @(bAWT or bDA[79] or bBWEBA[79]) begin : AWTQA79
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[79] = 1'bx; 
        #0.01;
       `endif
        bQA[79] = bDA[79] ^ bBWEBA[79];
    end
    end
end
always @(bAWT or bDB[79] or bBWEBB[79]) begin : AWTQB79
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[79] = 1'bx;
        #0.01;
        `endif
        bQB[79] = bDB[79] ^ bBWEBB[79];
    end
    end
end
always @(bAWT or bDA[80] or bBWEBA[80]) begin : AWTQA80
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[80] = 1'bx; 
        #0.01;
       `endif
        bQA[80] = bDA[80] ^ bBWEBA[80];
    end
    end
end
always @(bAWT or bDB[80] or bBWEBB[80]) begin : AWTQB80
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[80] = 1'bx;
        #0.01;
        `endif
        bQB[80] = bDB[80] ^ bBWEBB[80];
    end
    end
end
always @(bAWT or bDA[81] or bBWEBA[81]) begin : AWTQA81
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[81] = 1'bx; 
        #0.01;
       `endif
        bQA[81] = bDA[81] ^ bBWEBA[81];
    end
    end
end
always @(bAWT or bDB[81] or bBWEBB[81]) begin : AWTQB81
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[81] = 1'bx;
        #0.01;
        `endif
        bQB[81] = bDB[81] ^ bBWEBB[81];
    end
    end
end
always @(bAWT or bDA[82] or bBWEBA[82]) begin : AWTQA82
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[82] = 1'bx; 
        #0.01;
       `endif
        bQA[82] = bDA[82] ^ bBWEBA[82];
    end
    end
end
always @(bAWT or bDB[82] or bBWEBB[82]) begin : AWTQB82
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[82] = 1'bx;
        #0.01;
        `endif
        bQB[82] = bDB[82] ^ bBWEBB[82];
    end
    end
end
always @(bAWT or bDA[83] or bBWEBA[83]) begin : AWTQA83
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[83] = 1'bx; 
        #0.01;
       `endif
        bQA[83] = bDA[83] ^ bBWEBA[83];
    end
    end
end
always @(bAWT or bDB[83] or bBWEBB[83]) begin : AWTQB83
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[83] = 1'bx;
        #0.01;
        `endif
        bQB[83] = bDB[83] ^ bBWEBB[83];
    end
    end
end
always @(bAWT or bDA[84] or bBWEBA[84]) begin : AWTQA84
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[84] = 1'bx; 
        #0.01;
       `endif
        bQA[84] = bDA[84] ^ bBWEBA[84];
    end
    end
end
always @(bAWT or bDB[84] or bBWEBB[84]) begin : AWTQB84
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[84] = 1'bx;
        #0.01;
        `endif
        bQB[84] = bDB[84] ^ bBWEBB[84];
    end
    end
end
always @(bAWT or bDA[85] or bBWEBA[85]) begin : AWTQA85
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[85] = 1'bx; 
        #0.01;
       `endif
        bQA[85] = bDA[85] ^ bBWEBA[85];
    end
    end
end
always @(bAWT or bDB[85] or bBWEBB[85]) begin : AWTQB85
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[85] = 1'bx;
        #0.01;
        `endif
        bQB[85] = bDB[85] ^ bBWEBB[85];
    end
    end
end
always @(bAWT or bDA[86] or bBWEBA[86]) begin : AWTQA86
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[86] = 1'bx; 
        #0.01;
       `endif
        bQA[86] = bDA[86] ^ bBWEBA[86];
    end
    end
end
always @(bAWT or bDB[86] or bBWEBB[86]) begin : AWTQB86
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[86] = 1'bx;
        #0.01;
        `endif
        bQB[86] = bDB[86] ^ bBWEBB[86];
    end
    end
end
always @(bAWT or bDA[87] or bBWEBA[87]) begin : AWTQA87
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[87] = 1'bx; 
        #0.01;
       `endif
        bQA[87] = bDA[87] ^ bBWEBA[87];
    end
    end
end
always @(bAWT or bDB[87] or bBWEBB[87]) begin : AWTQB87
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[87] = 1'bx;
        #0.01;
        `endif
        bQB[87] = bDB[87] ^ bBWEBB[87];
    end
    end
end
always @(bAWT or bDA[88] or bBWEBA[88]) begin : AWTQA88
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[88] = 1'bx; 
        #0.01;
       `endif
        bQA[88] = bDA[88] ^ bBWEBA[88];
    end
    end
end
always @(bAWT or bDB[88] or bBWEBB[88]) begin : AWTQB88
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[88] = 1'bx;
        #0.01;
        `endif
        bQB[88] = bDB[88] ^ bBWEBB[88];
    end
    end
end
always @(bAWT or bDA[89] or bBWEBA[89]) begin : AWTQA89
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[89] = 1'bx; 
        #0.01;
       `endif
        bQA[89] = bDA[89] ^ bBWEBA[89];
    end
    end
end
always @(bAWT or bDB[89] or bBWEBB[89]) begin : AWTQB89
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[89] = 1'bx;
        #0.01;
        `endif
        bQB[89] = bDB[89] ^ bBWEBB[89];
    end
    end
end
always @(bAWT or bDA[90] or bBWEBA[90]) begin : AWTQA90
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[90] = 1'bx; 
        #0.01;
       `endif
        bQA[90] = bDA[90] ^ bBWEBA[90];
    end
    end
end
always @(bAWT or bDB[90] or bBWEBB[90]) begin : AWTQB90
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[90] = 1'bx;
        #0.01;
        `endif
        bQB[90] = bDB[90] ^ bBWEBB[90];
    end
    end
end
always @(bAWT or bDA[91] or bBWEBA[91]) begin : AWTQA91
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[91] = 1'bx; 
        #0.01;
       `endif
        bQA[91] = bDA[91] ^ bBWEBA[91];
    end
    end
end
always @(bAWT or bDB[91] or bBWEBB[91]) begin : AWTQB91
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[91] = 1'bx;
        #0.01;
        `endif
        bQB[91] = bDB[91] ^ bBWEBB[91];
    end
    end
end
always @(bAWT or bDA[92] or bBWEBA[92]) begin : AWTQA92
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[92] = 1'bx; 
        #0.01;
       `endif
        bQA[92] = bDA[92] ^ bBWEBA[92];
    end
    end
end
always @(bAWT or bDB[92] or bBWEBB[92]) begin : AWTQB92
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[92] = 1'bx;
        #0.01;
        `endif
        bQB[92] = bDB[92] ^ bBWEBB[92];
    end
    end
end
always @(bAWT or bDA[93] or bBWEBA[93]) begin : AWTQA93
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[93] = 1'bx; 
        #0.01;
       `endif
        bQA[93] = bDA[93] ^ bBWEBA[93];
    end
    end
end
always @(bAWT or bDB[93] or bBWEBB[93]) begin : AWTQB93
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[93] = 1'bx;
        #0.01;
        `endif
        bQB[93] = bDB[93] ^ bBWEBB[93];
    end
    end
end
always @(bAWT or bDA[94] or bBWEBA[94]) begin : AWTQA94
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[94] = 1'bx; 
        #0.01;
       `endif
        bQA[94] = bDA[94] ^ bBWEBA[94];
    end
    end
end
always @(bAWT or bDB[94] or bBWEBB[94]) begin : AWTQB94
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[94] = 1'bx;
        #0.01;
        `endif
        bQB[94] = bDB[94] ^ bBWEBB[94];
    end
    end
end
always @(bAWT or bDA[95] or bBWEBA[95]) begin : AWTQA95
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[95] = 1'bx; 
        #0.01;
       `endif
        bQA[95] = bDA[95] ^ bBWEBA[95];
    end
    end
end
always @(bAWT or bDB[95] or bBWEBB[95]) begin : AWTQB95
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[95] = 1'bx;
        #0.01;
        `endif
        bQB[95] = bDB[95] ^ bBWEBB[95];
    end
    end
end
always @(bAWT or bDA[96] or bBWEBA[96]) begin : AWTQA96
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[96] = 1'bx; 
        #0.01;
       `endif
        bQA[96] = bDA[96] ^ bBWEBA[96];
    end
    end
end
always @(bAWT or bDB[96] or bBWEBB[96]) begin : AWTQB96
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[96] = 1'bx;
        #0.01;
        `endif
        bQB[96] = bDB[96] ^ bBWEBB[96];
    end
    end
end
always @(bAWT or bDA[97] or bBWEBA[97]) begin : AWTQA97
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[97] = 1'bx; 
        #0.01;
       `endif
        bQA[97] = bDA[97] ^ bBWEBA[97];
    end
    end
end
always @(bAWT or bDB[97] or bBWEBB[97]) begin : AWTQB97
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[97] = 1'bx;
        #0.01;
        `endif
        bQB[97] = bDB[97] ^ bBWEBB[97];
    end
    end
end
always @(bAWT or bDA[98] or bBWEBA[98]) begin : AWTQA98
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[98] = 1'bx; 
        #0.01;
       `endif
        bQA[98] = bDA[98] ^ bBWEBA[98];
    end
    end
end
always @(bAWT or bDB[98] or bBWEBB[98]) begin : AWTQB98
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[98] = 1'bx;
        #0.01;
        `endif
        bQB[98] = bDB[98] ^ bBWEBB[98];
    end
    end
end
always @(bAWT or bDA[99] or bBWEBA[99]) begin : AWTQA99
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[99] = 1'bx; 
        #0.01;
       `endif
        bQA[99] = bDA[99] ^ bBWEBA[99];
    end
    end
end
always @(bAWT or bDB[99] or bBWEBB[99]) begin : AWTQB99
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[99] = 1'bx;
        #0.01;
        `endif
        bQB[99] = bDB[99] ^ bBWEBB[99];
    end
    end
end
always @(bAWT or bDA[100] or bBWEBA[100]) begin : AWTQA100
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[100] = 1'bx; 
        #0.01;
       `endif
        bQA[100] = bDA[100] ^ bBWEBA[100];
    end
    end
end
always @(bAWT or bDB[100] or bBWEBB[100]) begin : AWTQB100
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[100] = 1'bx;
        #0.01;
        `endif
        bQB[100] = bDB[100] ^ bBWEBB[100];
    end
    end
end
always @(bAWT or bDA[101] or bBWEBA[101]) begin : AWTQA101
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[101] = 1'bx; 
        #0.01;
       `endif
        bQA[101] = bDA[101] ^ bBWEBA[101];
    end
    end
end
always @(bAWT or bDB[101] or bBWEBB[101]) begin : AWTQB101
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[101] = 1'bx;
        #0.01;
        `endif
        bQB[101] = bDB[101] ^ bBWEBB[101];
    end
    end
end
always @(bAWT or bDA[102] or bBWEBA[102]) begin : AWTQA102
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[102] = 1'bx; 
        #0.01;
       `endif
        bQA[102] = bDA[102] ^ bBWEBA[102];
    end
    end
end
always @(bAWT or bDB[102] or bBWEBB[102]) begin : AWTQB102
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[102] = 1'bx;
        #0.01;
        `endif
        bQB[102] = bDB[102] ^ bBWEBB[102];
    end
    end
end
always @(bAWT or bDA[103] or bBWEBA[103]) begin : AWTQA103
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[103] = 1'bx; 
        #0.01;
       `endif
        bQA[103] = bDA[103] ^ bBWEBA[103];
    end
    end
end
always @(bAWT or bDB[103] or bBWEBB[103]) begin : AWTQB103
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[103] = 1'bx;
        #0.01;
        `endif
        bQB[103] = bDB[103] ^ bBWEBB[103];
    end
    end
end
always @(bAWT or bDA[104] or bBWEBA[104]) begin : AWTQA104
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[104] = 1'bx; 
        #0.01;
       `endif
        bQA[104] = bDA[104] ^ bBWEBA[104];
    end
    end
end
always @(bAWT or bDB[104] or bBWEBB[104]) begin : AWTQB104
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[104] = 1'bx;
        #0.01;
        `endif
        bQB[104] = bDB[104] ^ bBWEBB[104];
    end
    end
end
always @(bAWT or bDA[105] or bBWEBA[105]) begin : AWTQA105
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[105] = 1'bx; 
        #0.01;
       `endif
        bQA[105] = bDA[105] ^ bBWEBA[105];
    end
    end
end
always @(bAWT or bDB[105] or bBWEBB[105]) begin : AWTQB105
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[105] = 1'bx;
        #0.01;
        `endif
        bQB[105] = bDB[105] ^ bBWEBB[105];
    end
    end
end
always @(bAWT or bDA[106] or bBWEBA[106]) begin : AWTQA106
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[106] = 1'bx; 
        #0.01;
       `endif
        bQA[106] = bDA[106] ^ bBWEBA[106];
    end
    end
end
always @(bAWT or bDB[106] or bBWEBB[106]) begin : AWTQB106
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[106] = 1'bx;
        #0.01;
        `endif
        bQB[106] = bDB[106] ^ bBWEBB[106];
    end
    end
end
always @(bAWT or bDA[107] or bBWEBA[107]) begin : AWTQA107
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[107] = 1'bx; 
        #0.01;
       `endif
        bQA[107] = bDA[107] ^ bBWEBA[107];
    end
    end
end
always @(bAWT or bDB[107] or bBWEBB[107]) begin : AWTQB107
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[107] = 1'bx;
        #0.01;
        `endif
        bQB[107] = bDB[107] ^ bBWEBB[107];
    end
    end
end
always @(bAWT or bDA[108] or bBWEBA[108]) begin : AWTQA108
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[108] = 1'bx; 
        #0.01;
       `endif
        bQA[108] = bDA[108] ^ bBWEBA[108];
    end
    end
end
always @(bAWT or bDB[108] or bBWEBB[108]) begin : AWTQB108
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[108] = 1'bx;
        #0.01;
        `endif
        bQB[108] = bDB[108] ^ bBWEBB[108];
    end
    end
end
always @(bAWT or bDA[109] or bBWEBA[109]) begin : AWTQA109
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[109] = 1'bx; 
        #0.01;
       `endif
        bQA[109] = bDA[109] ^ bBWEBA[109];
    end
    end
end
always @(bAWT or bDB[109] or bBWEBB[109]) begin : AWTQB109
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[109] = 1'bx;
        #0.01;
        `endif
        bQB[109] = bDB[109] ^ bBWEBB[109];
    end
    end
end
always @(bAWT or bDA[110] or bBWEBA[110]) begin : AWTQA110
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[110] = 1'bx; 
        #0.01;
       `endif
        bQA[110] = bDA[110] ^ bBWEBA[110];
    end
    end
end
always @(bAWT or bDB[110] or bBWEBB[110]) begin : AWTQB110
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[110] = 1'bx;
        #0.01;
        `endif
        bQB[110] = bDB[110] ^ bBWEBB[110];
    end
    end
end
always @(bAWT or bDA[111] or bBWEBA[111]) begin : AWTQA111
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[111] = 1'bx; 
        #0.01;
       `endif
        bQA[111] = bDA[111] ^ bBWEBA[111];
    end
    end
end
always @(bAWT or bDB[111] or bBWEBB[111]) begin : AWTQB111
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[111] = 1'bx;
        #0.01;
        `endif
        bQB[111] = bDB[111] ^ bBWEBB[111];
    end
    end
end
always @(bAWT or bDA[112] or bBWEBA[112]) begin : AWTQA112
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[112] = 1'bx; 
        #0.01;
       `endif
        bQA[112] = bDA[112] ^ bBWEBA[112];
    end
    end
end
always @(bAWT or bDB[112] or bBWEBB[112]) begin : AWTQB112
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[112] = 1'bx;
        #0.01;
        `endif
        bQB[112] = bDB[112] ^ bBWEBB[112];
    end
    end
end
always @(bAWT or bDA[113] or bBWEBA[113]) begin : AWTQA113
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[113] = 1'bx; 
        #0.01;
       `endif
        bQA[113] = bDA[113] ^ bBWEBA[113];
    end
    end
end
always @(bAWT or bDB[113] or bBWEBB[113]) begin : AWTQB113
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[113] = 1'bx;
        #0.01;
        `endif
        bQB[113] = bDB[113] ^ bBWEBB[113];
    end
    end
end
always @(bAWT or bDA[114] or bBWEBA[114]) begin : AWTQA114
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[114] = 1'bx; 
        #0.01;
       `endif
        bQA[114] = bDA[114] ^ bBWEBA[114];
    end
    end
end
always @(bAWT or bDB[114] or bBWEBB[114]) begin : AWTQB114
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[114] = 1'bx;
        #0.01;
        `endif
        bQB[114] = bDB[114] ^ bBWEBB[114];
    end
    end
end
always @(bAWT or bDA[115] or bBWEBA[115]) begin : AWTQA115
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[115] = 1'bx; 
        #0.01;
       `endif
        bQA[115] = bDA[115] ^ bBWEBA[115];
    end
    end
end
always @(bAWT or bDB[115] or bBWEBB[115]) begin : AWTQB115
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[115] = 1'bx;
        #0.01;
        `endif
        bQB[115] = bDB[115] ^ bBWEBB[115];
    end
    end
end
always @(bAWT or bDA[116] or bBWEBA[116]) begin : AWTQA116
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[116] = 1'bx; 
        #0.01;
       `endif
        bQA[116] = bDA[116] ^ bBWEBA[116];
    end
    end
end
always @(bAWT or bDB[116] or bBWEBB[116]) begin : AWTQB116
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[116] = 1'bx;
        #0.01;
        `endif
        bQB[116] = bDB[116] ^ bBWEBB[116];
    end
    end
end
always @(bAWT or bDA[117] or bBWEBA[117]) begin : AWTQA117
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[117] = 1'bx; 
        #0.01;
       `endif
        bQA[117] = bDA[117] ^ bBWEBA[117];
    end
    end
end
always @(bAWT or bDB[117] or bBWEBB[117]) begin : AWTQB117
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[117] = 1'bx;
        #0.01;
        `endif
        bQB[117] = bDB[117] ^ bBWEBB[117];
    end
    end
end
always @(bAWT or bDA[118] or bBWEBA[118]) begin : AWTQA118
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[118] = 1'bx; 
        #0.01;
       `endif
        bQA[118] = bDA[118] ^ bBWEBA[118];
    end
    end
end
always @(bAWT or bDB[118] or bBWEBB[118]) begin : AWTQB118
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[118] = 1'bx;
        #0.01;
        `endif
        bQB[118] = bDB[118] ^ bBWEBB[118];
    end
    end
end
always @(bAWT or bDA[119] or bBWEBA[119]) begin : AWTQA119
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[119] = 1'bx; 
        #0.01;
       `endif
        bQA[119] = bDA[119] ^ bBWEBA[119];
    end
    end
end
always @(bAWT or bDB[119] or bBWEBB[119]) begin : AWTQB119
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[119] = 1'bx;
        #0.01;
        `endif
        bQB[119] = bDB[119] ^ bBWEBB[119];
    end
    end
end
always @(bAWT or bDA[120] or bBWEBA[120]) begin : AWTQA120
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[120] = 1'bx; 
        #0.01;
       `endif
        bQA[120] = bDA[120] ^ bBWEBA[120];
    end
    end
end
always @(bAWT or bDB[120] or bBWEBB[120]) begin : AWTQB120
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[120] = 1'bx;
        #0.01;
        `endif
        bQB[120] = bDB[120] ^ bBWEBB[120];
    end
    end
end
always @(bAWT or bDA[121] or bBWEBA[121]) begin : AWTQA121
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[121] = 1'bx; 
        #0.01;
       `endif
        bQA[121] = bDA[121] ^ bBWEBA[121];
    end
    end
end
always @(bAWT or bDB[121] or bBWEBB[121]) begin : AWTQB121
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[121] = 1'bx;
        #0.01;
        `endif
        bQB[121] = bDB[121] ^ bBWEBB[121];
    end
    end
end
always @(bAWT or bDA[122] or bBWEBA[122]) begin : AWTQA122
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[122] = 1'bx; 
        #0.01;
       `endif
        bQA[122] = bDA[122] ^ bBWEBA[122];
    end
    end
end
always @(bAWT or bDB[122] or bBWEBB[122]) begin : AWTQB122
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[122] = 1'bx;
        #0.01;
        `endif
        bQB[122] = bDB[122] ^ bBWEBB[122];
    end
    end
end
always @(bAWT or bDA[123] or bBWEBA[123]) begin : AWTQA123
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[123] = 1'bx; 
        #0.01;
       `endif
        bQA[123] = bDA[123] ^ bBWEBA[123];
    end
    end
end
always @(bAWT or bDB[123] or bBWEBB[123]) begin : AWTQB123
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[123] = 1'bx;
        #0.01;
        `endif
        bQB[123] = bDB[123] ^ bBWEBB[123];
    end
    end
end
always @(bAWT or bDA[124] or bBWEBA[124]) begin : AWTQA124
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[124] = 1'bx; 
        #0.01;
       `endif
        bQA[124] = bDA[124] ^ bBWEBA[124];
    end
    end
end
always @(bAWT or bDB[124] or bBWEBB[124]) begin : AWTQB124
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[124] = 1'bx;
        #0.01;
        `endif
        bQB[124] = bDB[124] ^ bBWEBB[124];
    end
    end
end
always @(bAWT or bDA[125] or bBWEBA[125]) begin : AWTQA125
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[125] = 1'bx; 
        #0.01;
       `endif
        bQA[125] = bDA[125] ^ bBWEBA[125];
    end
    end
end
always @(bAWT or bDB[125] or bBWEBB[125]) begin : AWTQB125
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[125] = 1'bx;
        #0.01;
        `endif
        bQB[125] = bDB[125] ^ bBWEBB[125];
    end
    end
end
always @(bAWT or bDA[126] or bBWEBA[126]) begin : AWTQA126
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[126] = 1'bx; 
        #0.01;
       `endif
        bQA[126] = bDA[126] ^ bBWEBA[126];
    end
    end
end
always @(bAWT or bDB[126] or bBWEBB[126]) begin : AWTQB126
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[126] = 1'bx;
        #0.01;
        `endif
        bQB[126] = bDB[126] ^ bBWEBB[126];
    end
    end
end
always @(bAWT or bDA[127] or bBWEBA[127]) begin : AWTQA127
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBAL === 1'b0 && WEBAL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
        end
    end
    if(bAWT && clk_count == 0) 
    begin
       `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQA[127] = 1'bx; 
        #0.01;
       `endif
        bQA[127] = bDA[127] ^ bBWEBA[127];
    end
    end
end
always @(bAWT or bDB[127] or bBWEBB[127]) begin : AWTQB127
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
    if(bAWT && clk_count == 0 && CEBBL === 1'b0 && WEBBL === 1'b1) 
    begin
        if( MES_ALL=="ON" && $realtime != 0)
        begin
            $display("\tInfo %m : Read operation failed when AWT is asserted at simulation time %t\n", $realtime);
         end
    end
    if(bAWT && clk_count == 0) 
    begin
        `ifdef TSMC_CM_UNIT_DELAY
        #(SRAM_DELAY);
        `else
        bQB[127] = 1'bx;
        #0.01;
        `endif
        bQB[127] = bDB[127] ^ bBWEBB[127];
    end
    end
end


always @(RDA or QAL) 
begin : CLKAROP
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0 && invalid_sdwk_dslp === 1'b0 && bAWT === 1'b0) begin
    if(!CEBAL && WEBAL && clk_count == 0) 
    begin
        begin
            if(bAWT !== 1'b1) begin
`ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
`else
            bQA = {N{1'bx}};
            #0.01;
`endif
            bQA <= QAL;
            end
        end
    end // if(!CEBAL && WEBAL && clk_count == 0)
    end
end // always @ (RDA or QAL)

always @(RDB or QBL) 
begin : CLKBROP
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0 && invalid_sdwk_dslp === 1'b0 && bAWT === 1'b0) begin
    if(!CEBBL && WEBBL && clk_count == 0) 
    begin
        begin
            if(bAWT !== 1'b1) begin
`ifdef TSMC_CM_UNIT_DELAY
            #(SRAM_DELAY);
`else
            bQB = {N{1'bx}};
            #0.01;
`endif
            bQB <= QBL;
            end
        end
    end // if(!bAWT && !CEBBL && WEBBL && clk_count == 0)
    end
end // always @ (RDB or QBL)




always @(bAWT) 
begin
    if(bSLP === 1'b0 && bDSLP === 1'b0 && bSD === 1'b0) begin
        if(bAWT === 1'bx) 
        begin
            if( MES_ALL=="ON" && $realtime != 0)
            begin
                $display("\nWarning %m AWT unknown, Outputs unknown at %t. >>", $realtime);
            end
            //xMemoryAll;
`ifdef TSMC_CM_UNIT_DELAY
            bQA <= #(SRAM_DELAY + 0.001) {N{1'bx}}; 
            bQB <= #(SRAM_DELAY + 0.001) {N{1'bx}};
`else  
            bQA <= #0.01 {N{1'bx}}; 
            bQB <= #0.01 {N{1'bx}};
`endif
        end
        else if(bAWT === 1'b1) begin
            disable CLKAROP;
            disable CLKBROP;
        end
        else if(bAWT === 1'b0) begin
            disable AWTQA0;
            disable AWTQB0;
            disable AWTQA1;
            disable AWTQB1;
            disable AWTQA2;
            disable AWTQB2;
            disable AWTQA3;
            disable AWTQB3;
            disable AWTQA4;
            disable AWTQB4;
            disable AWTQA5;
            disable AWTQB5;
            disable AWTQA6;
            disable AWTQB6;
            disable AWTQA7;
            disable AWTQB7;
            disable AWTQA8;
            disable AWTQB8;
            disable AWTQA9;
            disable AWTQB9;
            disable AWTQA10;
            disable AWTQB10;
            disable AWTQA11;
            disable AWTQB11;
            disable AWTQA12;
            disable AWTQB12;
            disable AWTQA13;
            disable AWTQB13;
            disable AWTQA14;
            disable AWTQB14;
            disable AWTQA15;
            disable AWTQB15;
            disable AWTQA16;
            disable AWTQB16;
            disable AWTQA17;
            disable AWTQB17;
            disable AWTQA18;
            disable AWTQB18;
            disable AWTQA19;
            disable AWTQB19;
            disable AWTQA20;
            disable AWTQB20;
            disable AWTQA21;
            disable AWTQB21;
            disable AWTQA22;
            disable AWTQB22;
            disable AWTQA23;
            disable AWTQB23;
            disable AWTQA24;
            disable AWTQB24;
            disable AWTQA25;
            disable AWTQB25;
            disable AWTQA26;
            disable AWTQB26;
            disable AWTQA27;
            disable AWTQB27;
            disable AWTQA28;
            disable AWTQB28;
            disable AWTQA29;
            disable AWTQB29;
            disable AWTQA30;
            disable AWTQB30;
            disable AWTQA31;
            disable AWTQB31;
            disable AWTQA32;
            disable AWTQB32;
            disable AWTQA33;
            disable AWTQB33;
            disable AWTQA34;
            disable AWTQB34;
            disable AWTQA35;
            disable AWTQB35;
            disable AWTQA36;
            disable AWTQB36;
            disable AWTQA37;
            disable AWTQB37;
            disable AWTQA38;
            disable AWTQB38;
            disable AWTQA39;
            disable AWTQB39;
            disable AWTQA40;
            disable AWTQB40;
            disable AWTQA41;
            disable AWTQB41;
            disable AWTQA42;
            disable AWTQB42;
            disable AWTQA43;
            disable AWTQB43;
            disable AWTQA44;
            disable AWTQB44;
            disable AWTQA45;
            disable AWTQB45;
            disable AWTQA46;
            disable AWTQB46;
            disable AWTQA47;
            disable AWTQB47;
            disable AWTQA48;
            disable AWTQB48;
            disable AWTQA49;
            disable AWTQB49;
            disable AWTQA50;
            disable AWTQB50;
            disable AWTQA51;
            disable AWTQB51;
            disable AWTQA52;
            disable AWTQB52;
            disable AWTQA53;
            disable AWTQB53;
            disable AWTQA54;
            disable AWTQB54;
            disable AWTQA55;
            disable AWTQB55;
            disable AWTQA56;
            disable AWTQB56;
            disable AWTQA57;
            disable AWTQB57;
            disable AWTQA58;
            disable AWTQB58;
            disable AWTQA59;
            disable AWTQB59;
            disable AWTQA60;
            disable AWTQB60;
            disable AWTQA61;
            disable AWTQB61;
            disable AWTQA62;
            disable AWTQB62;
            disable AWTQA63;
            disable AWTQB63;
            disable AWTQA64;
            disable AWTQB64;
            disable AWTQA65;
            disable AWTQB65;
            disable AWTQA66;
            disable AWTQB66;
            disable AWTQA67;
            disable AWTQB67;
            disable AWTQA68;
            disable AWTQB68;
            disable AWTQA69;
            disable AWTQB69;
            disable AWTQA70;
            disable AWTQB70;
            disable AWTQA71;
            disable AWTQB71;
            disable AWTQA72;
            disable AWTQB72;
            disable AWTQA73;
            disable AWTQB73;
            disable AWTQA74;
            disable AWTQB74;
            disable AWTQA75;
            disable AWTQB75;
            disable AWTQA76;
            disable AWTQB76;
            disable AWTQA77;
            disable AWTQB77;
            disable AWTQA78;
            disable AWTQB78;
            disable AWTQA79;
            disable AWTQB79;
            disable AWTQA80;
            disable AWTQB80;
            disable AWTQA81;
            disable AWTQB81;
            disable AWTQA82;
            disable AWTQB82;
            disable AWTQA83;
            disable AWTQB83;
            disable AWTQA84;
            disable AWTQB84;
            disable AWTQA85;
            disable AWTQB85;
            disable AWTQA86;
            disable AWTQB86;
            disable AWTQA87;
            disable AWTQB87;
            disable AWTQA88;
            disable AWTQB88;
            disable AWTQA89;
            disable AWTQB89;
            disable AWTQA90;
            disable AWTQB90;
            disable AWTQA91;
            disable AWTQB91;
            disable AWTQA92;
            disable AWTQB92;
            disable AWTQA93;
            disable AWTQB93;
            disable AWTQA94;
            disable AWTQB94;
            disable AWTQA95;
            disable AWTQB95;
            disable AWTQA96;
            disable AWTQB96;
            disable AWTQA97;
            disable AWTQB97;
            disable AWTQA98;
            disable AWTQB98;
            disable AWTQA99;
            disable AWTQB99;
            disable AWTQA100;
            disable AWTQB100;
            disable AWTQA101;
            disable AWTQB101;
            disable AWTQA102;
            disable AWTQB102;
            disable AWTQA103;
            disable AWTQB103;
            disable AWTQA104;
            disable AWTQB104;
            disable AWTQA105;
            disable AWTQB105;
            disable AWTQA106;
            disable AWTQB106;
            disable AWTQA107;
            disable AWTQB107;
            disable AWTQA108;
            disable AWTQB108;
            disable AWTQA109;
            disable AWTQB109;
            disable AWTQA110;
            disable AWTQB110;
            disable AWTQA111;
            disable AWTQB111;
            disable AWTQA112;
            disable AWTQB112;
            disable AWTQA113;
            disable AWTQB113;
            disable AWTQA114;
            disable AWTQB114;
            disable AWTQA115;
            disable AWTQB115;
            disable AWTQA116;
            disable AWTQB116;
            disable AWTQA117;
            disable AWTQB117;
            disable AWTQA118;
            disable AWTQB118;
            disable AWTQA119;
            disable AWTQB119;
            disable AWTQA120;
            disable AWTQB120;
            disable AWTQA121;
            disable AWTQB121;
            disable AWTQA122;
            disable AWTQB122;
            disable AWTQA123;
            disable AWTQB123;
            disable AWTQA124;
            disable AWTQB124;
            disable AWTQA125;
            disable AWTQB125;
            disable AWTQA126;
            disable AWTQB126;
            disable AWTQA127;
            disable AWTQB127;
            bQA <= {N{1'bx}}; 
            bQB <= {N{1'bx}};    
        end
    end
end

always @(BWEBAL) 
begin
    BWEBAL = #0.01 {N{1'b1}};
end

always @(BWEBBL) 
begin
    BWEBBL = #0.01 {N{1'b1}};
end

 
`ifdef TSMC_CM_UNIT_DELAY
`else 
always @(valid_testpin) begin
    AAL <= {M{1'bx}};
    BWEBAL <= {N{1'b0}};
    BWEBBL <= {N{1'b0}};
    if(bAWT !== 1'b1) begin
      bQA = #0.01 {N{1'bx}};
      bQB = #0.01 {N{1'bx}};
    end
end


always @(valid_ck) 
begin
    if (iCEBA === 1'b0) begin
        #0.002;
        AAL = {M{1'bx}};
        BWEBAL = {N{1'b0}};
        if(bAWT !== 1'b1) begin
          bQA = #0.01 {N{1'bx}};
        end
    end      

    if (iCEBB === 1'b0) begin
        #0.002;
        ABL = {M{1'bx}};
        BWEBBL = {N{1'b0}};
        if(bAWT !== 1'b1) begin
        bQB = #0.01 {N{1'bx}};
        end
    end      
end
 

always @(valid_cka) 
begin
    
    #0.002;
    AAL = {M{1'bx}};
    BWEBAL = {N{1'b0}};
    if(bAWT !== 1'b1) begin
      bQA = #0.01 {N{1'bx}};
    end
end
 
always @(valid_ckb) 
begin
    
    #0.002;
    ABL = {M{1'bx}};
    BWEBBL = {N{1'b0}};
    if(bAWT !== 1'b1) begin
      bQB = #0.01 {N{1'bx}};
    end
end


always @(valid_aa) 
begin
    
    if(!WEBAL) 
    begin
        #0.002;
        BWEBAL = {N{1'b0}};
        AAL = {M{1'bx}};
    end
    else 
    begin
        #0.002;
        BWEBAL = {N{1'b0}};
        AAL = {M{1'bx}};
        if(bAWT !== 1'b1) begin
            bQA = #0.01 {N{1'bx}};
        end
    end
end

always @(valid_ab) 
begin
    
    if(!WEBBL) 
    begin
        BWEBBL = {N{1'b0}};
        ABL = {M{1'bx}};
    end
    else 
    begin
        #0.002;
        BWEBBL = {N{1'b0}};
        ABL = {M{1'bx}};
        if(bAWT !== 1'b1) begin
            bQB = #0.01 {N{1'bx}};
        end
    end
end

always @(valid_da0) 
begin
    
    DAL[0] = 1'bx;
    BWEBAL[0] = 1'b0;
end

always @(valid_db0) 
begin
    disable CLKAOP;
    DBL[0] = 1'bx;
    BWEBBL[0] = 1'b0;
end

always @(valid_bwa0) 
begin
    
    DAL[0] = 1'bx;
    BWEBAL[0] = 1'b0;
end

always @(valid_bwb0) 
begin
    disable CLKAOP;
    DBL[0] = 1'bx;
    BWEBBL[0] = 1'b0;
end
always @(valid_da1) 
begin
    
    DAL[1] = 1'bx;
    BWEBAL[1] = 1'b0;
end

always @(valid_db1) 
begin
    disable CLKAOP;
    DBL[1] = 1'bx;
    BWEBBL[1] = 1'b0;
end

always @(valid_bwa1) 
begin
    
    DAL[1] = 1'bx;
    BWEBAL[1] = 1'b0;
end

always @(valid_bwb1) 
begin
    disable CLKAOP;
    DBL[1] = 1'bx;
    BWEBBL[1] = 1'b0;
end
always @(valid_da2) 
begin
    
    DAL[2] = 1'bx;
    BWEBAL[2] = 1'b0;
end

always @(valid_db2) 
begin
    disable CLKAOP;
    DBL[2] = 1'bx;
    BWEBBL[2] = 1'b0;
end

always @(valid_bwa2) 
begin
    
    DAL[2] = 1'bx;
    BWEBAL[2] = 1'b0;
end

always @(valid_bwb2) 
begin
    disable CLKAOP;
    DBL[2] = 1'bx;
    BWEBBL[2] = 1'b0;
end
always @(valid_da3) 
begin
    
    DAL[3] = 1'bx;
    BWEBAL[3] = 1'b0;
end

always @(valid_db3) 
begin
    disable CLKAOP;
    DBL[3] = 1'bx;
    BWEBBL[3] = 1'b0;
end

always @(valid_bwa3) 
begin
    
    DAL[3] = 1'bx;
    BWEBAL[3] = 1'b0;
end

always @(valid_bwb3) 
begin
    disable CLKAOP;
    DBL[3] = 1'bx;
    BWEBBL[3] = 1'b0;
end
always @(valid_da4) 
begin
    
    DAL[4] = 1'bx;
    BWEBAL[4] = 1'b0;
end

always @(valid_db4) 
begin
    disable CLKAOP;
    DBL[4] = 1'bx;
    BWEBBL[4] = 1'b0;
end

always @(valid_bwa4) 
begin
    
    DAL[4] = 1'bx;
    BWEBAL[4] = 1'b0;
end

always @(valid_bwb4) 
begin
    disable CLKAOP;
    DBL[4] = 1'bx;
    BWEBBL[4] = 1'b0;
end
always @(valid_da5) 
begin
    
    DAL[5] = 1'bx;
    BWEBAL[5] = 1'b0;
end

always @(valid_db5) 
begin
    disable CLKAOP;
    DBL[5] = 1'bx;
    BWEBBL[5] = 1'b0;
end

always @(valid_bwa5) 
begin
    
    DAL[5] = 1'bx;
    BWEBAL[5] = 1'b0;
end

always @(valid_bwb5) 
begin
    disable CLKAOP;
    DBL[5] = 1'bx;
    BWEBBL[5] = 1'b0;
end
always @(valid_da6) 
begin
    
    DAL[6] = 1'bx;
    BWEBAL[6] = 1'b0;
end

always @(valid_db6) 
begin
    disable CLKAOP;
    DBL[6] = 1'bx;
    BWEBBL[6] = 1'b0;
end

always @(valid_bwa6) 
begin
    
    DAL[6] = 1'bx;
    BWEBAL[6] = 1'b0;
end

always @(valid_bwb6) 
begin
    disable CLKAOP;
    DBL[6] = 1'bx;
    BWEBBL[6] = 1'b0;
end
always @(valid_da7) 
begin
    
    DAL[7] = 1'bx;
    BWEBAL[7] = 1'b0;
end

always @(valid_db7) 
begin
    disable CLKAOP;
    DBL[7] = 1'bx;
    BWEBBL[7] = 1'b0;
end

always @(valid_bwa7) 
begin
    
    DAL[7] = 1'bx;
    BWEBAL[7] = 1'b0;
end

always @(valid_bwb7) 
begin
    disable CLKAOP;
    DBL[7] = 1'bx;
    BWEBBL[7] = 1'b0;
end
always @(valid_da8) 
begin
    
    DAL[8] = 1'bx;
    BWEBAL[8] = 1'b0;
end

always @(valid_db8) 
begin
    disable CLKAOP;
    DBL[8] = 1'bx;
    BWEBBL[8] = 1'b0;
end

always @(valid_bwa8) 
begin
    
    DAL[8] = 1'bx;
    BWEBAL[8] = 1'b0;
end

always @(valid_bwb8) 
begin
    disable CLKAOP;
    DBL[8] = 1'bx;
    BWEBBL[8] = 1'b0;
end
always @(valid_da9) 
begin
    
    DAL[9] = 1'bx;
    BWEBAL[9] = 1'b0;
end

always @(valid_db9) 
begin
    disable CLKAOP;
    DBL[9] = 1'bx;
    BWEBBL[9] = 1'b0;
end

always @(valid_bwa9) 
begin
    
    DAL[9] = 1'bx;
    BWEBAL[9] = 1'b0;
end

always @(valid_bwb9) 
begin
    disable CLKAOP;
    DBL[9] = 1'bx;
    BWEBBL[9] = 1'b0;
end
always @(valid_da10) 
begin
    
    DAL[10] = 1'bx;
    BWEBAL[10] = 1'b0;
end

always @(valid_db10) 
begin
    disable CLKAOP;
    DBL[10] = 1'bx;
    BWEBBL[10] = 1'b0;
end

always @(valid_bwa10) 
begin
    
    DAL[10] = 1'bx;
    BWEBAL[10] = 1'b0;
end

always @(valid_bwb10) 
begin
    disable CLKAOP;
    DBL[10] = 1'bx;
    BWEBBL[10] = 1'b0;
end
always @(valid_da11) 
begin
    
    DAL[11] = 1'bx;
    BWEBAL[11] = 1'b0;
end

always @(valid_db11) 
begin
    disable CLKAOP;
    DBL[11] = 1'bx;
    BWEBBL[11] = 1'b0;
end

always @(valid_bwa11) 
begin
    
    DAL[11] = 1'bx;
    BWEBAL[11] = 1'b0;
end

always @(valid_bwb11) 
begin
    disable CLKAOP;
    DBL[11] = 1'bx;
    BWEBBL[11] = 1'b0;
end
always @(valid_da12) 
begin
    
    DAL[12] = 1'bx;
    BWEBAL[12] = 1'b0;
end

always @(valid_db12) 
begin
    disable CLKAOP;
    DBL[12] = 1'bx;
    BWEBBL[12] = 1'b0;
end

always @(valid_bwa12) 
begin
    
    DAL[12] = 1'bx;
    BWEBAL[12] = 1'b0;
end

always @(valid_bwb12) 
begin
    disable CLKAOP;
    DBL[12] = 1'bx;
    BWEBBL[12] = 1'b0;
end
always @(valid_da13) 
begin
    
    DAL[13] = 1'bx;
    BWEBAL[13] = 1'b0;
end

always @(valid_db13) 
begin
    disable CLKAOP;
    DBL[13] = 1'bx;
    BWEBBL[13] = 1'b0;
end

always @(valid_bwa13) 
begin
    
    DAL[13] = 1'bx;
    BWEBAL[13] = 1'b0;
end

always @(valid_bwb13) 
begin
    disable CLKAOP;
    DBL[13] = 1'bx;
    BWEBBL[13] = 1'b0;
end
always @(valid_da14) 
begin
    
    DAL[14] = 1'bx;
    BWEBAL[14] = 1'b0;
end

always @(valid_db14) 
begin
    disable CLKAOP;
    DBL[14] = 1'bx;
    BWEBBL[14] = 1'b0;
end

always @(valid_bwa14) 
begin
    
    DAL[14] = 1'bx;
    BWEBAL[14] = 1'b0;
end

always @(valid_bwb14) 
begin
    disable CLKAOP;
    DBL[14] = 1'bx;
    BWEBBL[14] = 1'b0;
end
always @(valid_da15) 
begin
    
    DAL[15] = 1'bx;
    BWEBAL[15] = 1'b0;
end

always @(valid_db15) 
begin
    disable CLKAOP;
    DBL[15] = 1'bx;
    BWEBBL[15] = 1'b0;
end

always @(valid_bwa15) 
begin
    
    DAL[15] = 1'bx;
    BWEBAL[15] = 1'b0;
end

always @(valid_bwb15) 
begin
    disable CLKAOP;
    DBL[15] = 1'bx;
    BWEBBL[15] = 1'b0;
end
always @(valid_da16) 
begin
    
    DAL[16] = 1'bx;
    BWEBAL[16] = 1'b0;
end

always @(valid_db16) 
begin
    disable CLKAOP;
    DBL[16] = 1'bx;
    BWEBBL[16] = 1'b0;
end

always @(valid_bwa16) 
begin
    
    DAL[16] = 1'bx;
    BWEBAL[16] = 1'b0;
end

always @(valid_bwb16) 
begin
    disable CLKAOP;
    DBL[16] = 1'bx;
    BWEBBL[16] = 1'b0;
end
always @(valid_da17) 
begin
    
    DAL[17] = 1'bx;
    BWEBAL[17] = 1'b0;
end

always @(valid_db17) 
begin
    disable CLKAOP;
    DBL[17] = 1'bx;
    BWEBBL[17] = 1'b0;
end

always @(valid_bwa17) 
begin
    
    DAL[17] = 1'bx;
    BWEBAL[17] = 1'b0;
end

always @(valid_bwb17) 
begin
    disable CLKAOP;
    DBL[17] = 1'bx;
    BWEBBL[17] = 1'b0;
end
always @(valid_da18) 
begin
    
    DAL[18] = 1'bx;
    BWEBAL[18] = 1'b0;
end

always @(valid_db18) 
begin
    disable CLKAOP;
    DBL[18] = 1'bx;
    BWEBBL[18] = 1'b0;
end

always @(valid_bwa18) 
begin
    
    DAL[18] = 1'bx;
    BWEBAL[18] = 1'b0;
end

always @(valid_bwb18) 
begin
    disable CLKAOP;
    DBL[18] = 1'bx;
    BWEBBL[18] = 1'b0;
end
always @(valid_da19) 
begin
    
    DAL[19] = 1'bx;
    BWEBAL[19] = 1'b0;
end

always @(valid_db19) 
begin
    disable CLKAOP;
    DBL[19] = 1'bx;
    BWEBBL[19] = 1'b0;
end

always @(valid_bwa19) 
begin
    
    DAL[19] = 1'bx;
    BWEBAL[19] = 1'b0;
end

always @(valid_bwb19) 
begin
    disable CLKAOP;
    DBL[19] = 1'bx;
    BWEBBL[19] = 1'b0;
end
always @(valid_da20) 
begin
    
    DAL[20] = 1'bx;
    BWEBAL[20] = 1'b0;
end

always @(valid_db20) 
begin
    disable CLKAOP;
    DBL[20] = 1'bx;
    BWEBBL[20] = 1'b0;
end

always @(valid_bwa20) 
begin
    
    DAL[20] = 1'bx;
    BWEBAL[20] = 1'b0;
end

always @(valid_bwb20) 
begin
    disable CLKAOP;
    DBL[20] = 1'bx;
    BWEBBL[20] = 1'b0;
end
always @(valid_da21) 
begin
    
    DAL[21] = 1'bx;
    BWEBAL[21] = 1'b0;
end

always @(valid_db21) 
begin
    disable CLKAOP;
    DBL[21] = 1'bx;
    BWEBBL[21] = 1'b0;
end

always @(valid_bwa21) 
begin
    
    DAL[21] = 1'bx;
    BWEBAL[21] = 1'b0;
end

always @(valid_bwb21) 
begin
    disable CLKAOP;
    DBL[21] = 1'bx;
    BWEBBL[21] = 1'b0;
end
always @(valid_da22) 
begin
    
    DAL[22] = 1'bx;
    BWEBAL[22] = 1'b0;
end

always @(valid_db22) 
begin
    disable CLKAOP;
    DBL[22] = 1'bx;
    BWEBBL[22] = 1'b0;
end

always @(valid_bwa22) 
begin
    
    DAL[22] = 1'bx;
    BWEBAL[22] = 1'b0;
end

always @(valid_bwb22) 
begin
    disable CLKAOP;
    DBL[22] = 1'bx;
    BWEBBL[22] = 1'b0;
end
always @(valid_da23) 
begin
    
    DAL[23] = 1'bx;
    BWEBAL[23] = 1'b0;
end

always @(valid_db23) 
begin
    disable CLKAOP;
    DBL[23] = 1'bx;
    BWEBBL[23] = 1'b0;
end

always @(valid_bwa23) 
begin
    
    DAL[23] = 1'bx;
    BWEBAL[23] = 1'b0;
end

always @(valid_bwb23) 
begin
    disable CLKAOP;
    DBL[23] = 1'bx;
    BWEBBL[23] = 1'b0;
end
always @(valid_da24) 
begin
    
    DAL[24] = 1'bx;
    BWEBAL[24] = 1'b0;
end

always @(valid_db24) 
begin
    disable CLKAOP;
    DBL[24] = 1'bx;
    BWEBBL[24] = 1'b0;
end

always @(valid_bwa24) 
begin
    
    DAL[24] = 1'bx;
    BWEBAL[24] = 1'b0;
end

always @(valid_bwb24) 
begin
    disable CLKAOP;
    DBL[24] = 1'bx;
    BWEBBL[24] = 1'b0;
end
always @(valid_da25) 
begin
    
    DAL[25] = 1'bx;
    BWEBAL[25] = 1'b0;
end

always @(valid_db25) 
begin
    disable CLKAOP;
    DBL[25] = 1'bx;
    BWEBBL[25] = 1'b0;
end

always @(valid_bwa25) 
begin
    
    DAL[25] = 1'bx;
    BWEBAL[25] = 1'b0;
end

always @(valid_bwb25) 
begin
    disable CLKAOP;
    DBL[25] = 1'bx;
    BWEBBL[25] = 1'b0;
end
always @(valid_da26) 
begin
    
    DAL[26] = 1'bx;
    BWEBAL[26] = 1'b0;
end

always @(valid_db26) 
begin
    disable CLKAOP;
    DBL[26] = 1'bx;
    BWEBBL[26] = 1'b0;
end

always @(valid_bwa26) 
begin
    
    DAL[26] = 1'bx;
    BWEBAL[26] = 1'b0;
end

always @(valid_bwb26) 
begin
    disable CLKAOP;
    DBL[26] = 1'bx;
    BWEBBL[26] = 1'b0;
end
always @(valid_da27) 
begin
    
    DAL[27] = 1'bx;
    BWEBAL[27] = 1'b0;
end

always @(valid_db27) 
begin
    disable CLKAOP;
    DBL[27] = 1'bx;
    BWEBBL[27] = 1'b0;
end

always @(valid_bwa27) 
begin
    
    DAL[27] = 1'bx;
    BWEBAL[27] = 1'b0;
end

always @(valid_bwb27) 
begin
    disable CLKAOP;
    DBL[27] = 1'bx;
    BWEBBL[27] = 1'b0;
end
always @(valid_da28) 
begin
    
    DAL[28] = 1'bx;
    BWEBAL[28] = 1'b0;
end

always @(valid_db28) 
begin
    disable CLKAOP;
    DBL[28] = 1'bx;
    BWEBBL[28] = 1'b0;
end

always @(valid_bwa28) 
begin
    
    DAL[28] = 1'bx;
    BWEBAL[28] = 1'b0;
end

always @(valid_bwb28) 
begin
    disable CLKAOP;
    DBL[28] = 1'bx;
    BWEBBL[28] = 1'b0;
end
always @(valid_da29) 
begin
    
    DAL[29] = 1'bx;
    BWEBAL[29] = 1'b0;
end

always @(valid_db29) 
begin
    disable CLKAOP;
    DBL[29] = 1'bx;
    BWEBBL[29] = 1'b0;
end

always @(valid_bwa29) 
begin
    
    DAL[29] = 1'bx;
    BWEBAL[29] = 1'b0;
end

always @(valid_bwb29) 
begin
    disable CLKAOP;
    DBL[29] = 1'bx;
    BWEBBL[29] = 1'b0;
end
always @(valid_da30) 
begin
    
    DAL[30] = 1'bx;
    BWEBAL[30] = 1'b0;
end

always @(valid_db30) 
begin
    disable CLKAOP;
    DBL[30] = 1'bx;
    BWEBBL[30] = 1'b0;
end

always @(valid_bwa30) 
begin
    
    DAL[30] = 1'bx;
    BWEBAL[30] = 1'b0;
end

always @(valid_bwb30) 
begin
    disable CLKAOP;
    DBL[30] = 1'bx;
    BWEBBL[30] = 1'b0;
end
always @(valid_da31) 
begin
    
    DAL[31] = 1'bx;
    BWEBAL[31] = 1'b0;
end

always @(valid_db31) 
begin
    disable CLKAOP;
    DBL[31] = 1'bx;
    BWEBBL[31] = 1'b0;
end

always @(valid_bwa31) 
begin
    
    DAL[31] = 1'bx;
    BWEBAL[31] = 1'b0;
end

always @(valid_bwb31) 
begin
    disable CLKAOP;
    DBL[31] = 1'bx;
    BWEBBL[31] = 1'b0;
end
always @(valid_da32) 
begin
    
    DAL[32] = 1'bx;
    BWEBAL[32] = 1'b0;
end

always @(valid_db32) 
begin
    disable CLKAOP;
    DBL[32] = 1'bx;
    BWEBBL[32] = 1'b0;
end

always @(valid_bwa32) 
begin
    
    DAL[32] = 1'bx;
    BWEBAL[32] = 1'b0;
end

always @(valid_bwb32) 
begin
    disable CLKAOP;
    DBL[32] = 1'bx;
    BWEBBL[32] = 1'b0;
end
always @(valid_da33) 
begin
    
    DAL[33] = 1'bx;
    BWEBAL[33] = 1'b0;
end

always @(valid_db33) 
begin
    disable CLKAOP;
    DBL[33] = 1'bx;
    BWEBBL[33] = 1'b0;
end

always @(valid_bwa33) 
begin
    
    DAL[33] = 1'bx;
    BWEBAL[33] = 1'b0;
end

always @(valid_bwb33) 
begin
    disable CLKAOP;
    DBL[33] = 1'bx;
    BWEBBL[33] = 1'b0;
end
always @(valid_da34) 
begin
    
    DAL[34] = 1'bx;
    BWEBAL[34] = 1'b0;
end

always @(valid_db34) 
begin
    disable CLKAOP;
    DBL[34] = 1'bx;
    BWEBBL[34] = 1'b0;
end

always @(valid_bwa34) 
begin
    
    DAL[34] = 1'bx;
    BWEBAL[34] = 1'b0;
end

always @(valid_bwb34) 
begin
    disable CLKAOP;
    DBL[34] = 1'bx;
    BWEBBL[34] = 1'b0;
end
always @(valid_da35) 
begin
    
    DAL[35] = 1'bx;
    BWEBAL[35] = 1'b0;
end

always @(valid_db35) 
begin
    disable CLKAOP;
    DBL[35] = 1'bx;
    BWEBBL[35] = 1'b0;
end

always @(valid_bwa35) 
begin
    
    DAL[35] = 1'bx;
    BWEBAL[35] = 1'b0;
end

always @(valid_bwb35) 
begin
    disable CLKAOP;
    DBL[35] = 1'bx;
    BWEBBL[35] = 1'b0;
end
always @(valid_da36) 
begin
    
    DAL[36] = 1'bx;
    BWEBAL[36] = 1'b0;
end

always @(valid_db36) 
begin
    disable CLKAOP;
    DBL[36] = 1'bx;
    BWEBBL[36] = 1'b0;
end

always @(valid_bwa36) 
begin
    
    DAL[36] = 1'bx;
    BWEBAL[36] = 1'b0;
end

always @(valid_bwb36) 
begin
    disable CLKAOP;
    DBL[36] = 1'bx;
    BWEBBL[36] = 1'b0;
end
always @(valid_da37) 
begin
    
    DAL[37] = 1'bx;
    BWEBAL[37] = 1'b0;
end

always @(valid_db37) 
begin
    disable CLKAOP;
    DBL[37] = 1'bx;
    BWEBBL[37] = 1'b0;
end

always @(valid_bwa37) 
begin
    
    DAL[37] = 1'bx;
    BWEBAL[37] = 1'b0;
end

always @(valid_bwb37) 
begin
    disable CLKAOP;
    DBL[37] = 1'bx;
    BWEBBL[37] = 1'b0;
end
always @(valid_da38) 
begin
    
    DAL[38] = 1'bx;
    BWEBAL[38] = 1'b0;
end

always @(valid_db38) 
begin
    disable CLKAOP;
    DBL[38] = 1'bx;
    BWEBBL[38] = 1'b0;
end

always @(valid_bwa38) 
begin
    
    DAL[38] = 1'bx;
    BWEBAL[38] = 1'b0;
end

always @(valid_bwb38) 
begin
    disable CLKAOP;
    DBL[38] = 1'bx;
    BWEBBL[38] = 1'b0;
end
always @(valid_da39) 
begin
    
    DAL[39] = 1'bx;
    BWEBAL[39] = 1'b0;
end

always @(valid_db39) 
begin
    disable CLKAOP;
    DBL[39] = 1'bx;
    BWEBBL[39] = 1'b0;
end

always @(valid_bwa39) 
begin
    
    DAL[39] = 1'bx;
    BWEBAL[39] = 1'b0;
end

always @(valid_bwb39) 
begin
    disable CLKAOP;
    DBL[39] = 1'bx;
    BWEBBL[39] = 1'b0;
end
always @(valid_da40) 
begin
    
    DAL[40] = 1'bx;
    BWEBAL[40] = 1'b0;
end

always @(valid_db40) 
begin
    disable CLKAOP;
    DBL[40] = 1'bx;
    BWEBBL[40] = 1'b0;
end

always @(valid_bwa40) 
begin
    
    DAL[40] = 1'bx;
    BWEBAL[40] = 1'b0;
end

always @(valid_bwb40) 
begin
    disable CLKAOP;
    DBL[40] = 1'bx;
    BWEBBL[40] = 1'b0;
end
always @(valid_da41) 
begin
    
    DAL[41] = 1'bx;
    BWEBAL[41] = 1'b0;
end

always @(valid_db41) 
begin
    disable CLKAOP;
    DBL[41] = 1'bx;
    BWEBBL[41] = 1'b0;
end

always @(valid_bwa41) 
begin
    
    DAL[41] = 1'bx;
    BWEBAL[41] = 1'b0;
end

always @(valid_bwb41) 
begin
    disable CLKAOP;
    DBL[41] = 1'bx;
    BWEBBL[41] = 1'b0;
end
always @(valid_da42) 
begin
    
    DAL[42] = 1'bx;
    BWEBAL[42] = 1'b0;
end

always @(valid_db42) 
begin
    disable CLKAOP;
    DBL[42] = 1'bx;
    BWEBBL[42] = 1'b0;
end

always @(valid_bwa42) 
begin
    
    DAL[42] = 1'bx;
    BWEBAL[42] = 1'b0;
end

always @(valid_bwb42) 
begin
    disable CLKAOP;
    DBL[42] = 1'bx;
    BWEBBL[42] = 1'b0;
end
always @(valid_da43) 
begin
    
    DAL[43] = 1'bx;
    BWEBAL[43] = 1'b0;
end

always @(valid_db43) 
begin
    disable CLKAOP;
    DBL[43] = 1'bx;
    BWEBBL[43] = 1'b0;
end

always @(valid_bwa43) 
begin
    
    DAL[43] = 1'bx;
    BWEBAL[43] = 1'b0;
end

always @(valid_bwb43) 
begin
    disable CLKAOP;
    DBL[43] = 1'bx;
    BWEBBL[43] = 1'b0;
end
always @(valid_da44) 
begin
    
    DAL[44] = 1'bx;
    BWEBAL[44] = 1'b0;
end

always @(valid_db44) 
begin
    disable CLKAOP;
    DBL[44] = 1'bx;
    BWEBBL[44] = 1'b0;
end

always @(valid_bwa44) 
begin
    
    DAL[44] = 1'bx;
    BWEBAL[44] = 1'b0;
end

always @(valid_bwb44) 
begin
    disable CLKAOP;
    DBL[44] = 1'bx;
    BWEBBL[44] = 1'b0;
end
always @(valid_da45) 
begin
    
    DAL[45] = 1'bx;
    BWEBAL[45] = 1'b0;
end

always @(valid_db45) 
begin
    disable CLKAOP;
    DBL[45] = 1'bx;
    BWEBBL[45] = 1'b0;
end

always @(valid_bwa45) 
begin
    
    DAL[45] = 1'bx;
    BWEBAL[45] = 1'b0;
end

always @(valid_bwb45) 
begin
    disable CLKAOP;
    DBL[45] = 1'bx;
    BWEBBL[45] = 1'b0;
end
always @(valid_da46) 
begin
    
    DAL[46] = 1'bx;
    BWEBAL[46] = 1'b0;
end

always @(valid_db46) 
begin
    disable CLKAOP;
    DBL[46] = 1'bx;
    BWEBBL[46] = 1'b0;
end

always @(valid_bwa46) 
begin
    
    DAL[46] = 1'bx;
    BWEBAL[46] = 1'b0;
end

always @(valid_bwb46) 
begin
    disable CLKAOP;
    DBL[46] = 1'bx;
    BWEBBL[46] = 1'b0;
end
always @(valid_da47) 
begin
    
    DAL[47] = 1'bx;
    BWEBAL[47] = 1'b0;
end

always @(valid_db47) 
begin
    disable CLKAOP;
    DBL[47] = 1'bx;
    BWEBBL[47] = 1'b0;
end

always @(valid_bwa47) 
begin
    
    DAL[47] = 1'bx;
    BWEBAL[47] = 1'b0;
end

always @(valid_bwb47) 
begin
    disable CLKAOP;
    DBL[47] = 1'bx;
    BWEBBL[47] = 1'b0;
end
always @(valid_da48) 
begin
    
    DAL[48] = 1'bx;
    BWEBAL[48] = 1'b0;
end

always @(valid_db48) 
begin
    disable CLKAOP;
    DBL[48] = 1'bx;
    BWEBBL[48] = 1'b0;
end

always @(valid_bwa48) 
begin
    
    DAL[48] = 1'bx;
    BWEBAL[48] = 1'b0;
end

always @(valid_bwb48) 
begin
    disable CLKAOP;
    DBL[48] = 1'bx;
    BWEBBL[48] = 1'b0;
end
always @(valid_da49) 
begin
    
    DAL[49] = 1'bx;
    BWEBAL[49] = 1'b0;
end

always @(valid_db49) 
begin
    disable CLKAOP;
    DBL[49] = 1'bx;
    BWEBBL[49] = 1'b0;
end

always @(valid_bwa49) 
begin
    
    DAL[49] = 1'bx;
    BWEBAL[49] = 1'b0;
end

always @(valid_bwb49) 
begin
    disable CLKAOP;
    DBL[49] = 1'bx;
    BWEBBL[49] = 1'b0;
end
always @(valid_da50) 
begin
    
    DAL[50] = 1'bx;
    BWEBAL[50] = 1'b0;
end

always @(valid_db50) 
begin
    disable CLKAOP;
    DBL[50] = 1'bx;
    BWEBBL[50] = 1'b0;
end

always @(valid_bwa50) 
begin
    
    DAL[50] = 1'bx;
    BWEBAL[50] = 1'b0;
end

always @(valid_bwb50) 
begin
    disable CLKAOP;
    DBL[50] = 1'bx;
    BWEBBL[50] = 1'b0;
end
always @(valid_da51) 
begin
    
    DAL[51] = 1'bx;
    BWEBAL[51] = 1'b0;
end

always @(valid_db51) 
begin
    disable CLKAOP;
    DBL[51] = 1'bx;
    BWEBBL[51] = 1'b0;
end

always @(valid_bwa51) 
begin
    
    DAL[51] = 1'bx;
    BWEBAL[51] = 1'b0;
end

always @(valid_bwb51) 
begin
    disable CLKAOP;
    DBL[51] = 1'bx;
    BWEBBL[51] = 1'b0;
end
always @(valid_da52) 
begin
    
    DAL[52] = 1'bx;
    BWEBAL[52] = 1'b0;
end

always @(valid_db52) 
begin
    disable CLKAOP;
    DBL[52] = 1'bx;
    BWEBBL[52] = 1'b0;
end

always @(valid_bwa52) 
begin
    
    DAL[52] = 1'bx;
    BWEBAL[52] = 1'b0;
end

always @(valid_bwb52) 
begin
    disable CLKAOP;
    DBL[52] = 1'bx;
    BWEBBL[52] = 1'b0;
end
always @(valid_da53) 
begin
    
    DAL[53] = 1'bx;
    BWEBAL[53] = 1'b0;
end

always @(valid_db53) 
begin
    disable CLKAOP;
    DBL[53] = 1'bx;
    BWEBBL[53] = 1'b0;
end

always @(valid_bwa53) 
begin
    
    DAL[53] = 1'bx;
    BWEBAL[53] = 1'b0;
end

always @(valid_bwb53) 
begin
    disable CLKAOP;
    DBL[53] = 1'bx;
    BWEBBL[53] = 1'b0;
end
always @(valid_da54) 
begin
    
    DAL[54] = 1'bx;
    BWEBAL[54] = 1'b0;
end

always @(valid_db54) 
begin
    disable CLKAOP;
    DBL[54] = 1'bx;
    BWEBBL[54] = 1'b0;
end

always @(valid_bwa54) 
begin
    
    DAL[54] = 1'bx;
    BWEBAL[54] = 1'b0;
end

always @(valid_bwb54) 
begin
    disable CLKAOP;
    DBL[54] = 1'bx;
    BWEBBL[54] = 1'b0;
end
always @(valid_da55) 
begin
    
    DAL[55] = 1'bx;
    BWEBAL[55] = 1'b0;
end

always @(valid_db55) 
begin
    disable CLKAOP;
    DBL[55] = 1'bx;
    BWEBBL[55] = 1'b0;
end

always @(valid_bwa55) 
begin
    
    DAL[55] = 1'bx;
    BWEBAL[55] = 1'b0;
end

always @(valid_bwb55) 
begin
    disable CLKAOP;
    DBL[55] = 1'bx;
    BWEBBL[55] = 1'b0;
end
always @(valid_da56) 
begin
    
    DAL[56] = 1'bx;
    BWEBAL[56] = 1'b0;
end

always @(valid_db56) 
begin
    disable CLKAOP;
    DBL[56] = 1'bx;
    BWEBBL[56] = 1'b0;
end

always @(valid_bwa56) 
begin
    
    DAL[56] = 1'bx;
    BWEBAL[56] = 1'b0;
end

always @(valid_bwb56) 
begin
    disable CLKAOP;
    DBL[56] = 1'bx;
    BWEBBL[56] = 1'b0;
end
always @(valid_da57) 
begin
    
    DAL[57] = 1'bx;
    BWEBAL[57] = 1'b0;
end

always @(valid_db57) 
begin
    disable CLKAOP;
    DBL[57] = 1'bx;
    BWEBBL[57] = 1'b0;
end

always @(valid_bwa57) 
begin
    
    DAL[57] = 1'bx;
    BWEBAL[57] = 1'b0;
end

always @(valid_bwb57) 
begin
    disable CLKAOP;
    DBL[57] = 1'bx;
    BWEBBL[57] = 1'b0;
end
always @(valid_da58) 
begin
    
    DAL[58] = 1'bx;
    BWEBAL[58] = 1'b0;
end

always @(valid_db58) 
begin
    disable CLKAOP;
    DBL[58] = 1'bx;
    BWEBBL[58] = 1'b0;
end

always @(valid_bwa58) 
begin
    
    DAL[58] = 1'bx;
    BWEBAL[58] = 1'b0;
end

always @(valid_bwb58) 
begin
    disable CLKAOP;
    DBL[58] = 1'bx;
    BWEBBL[58] = 1'b0;
end
always @(valid_da59) 
begin
    
    DAL[59] = 1'bx;
    BWEBAL[59] = 1'b0;
end

always @(valid_db59) 
begin
    disable CLKAOP;
    DBL[59] = 1'bx;
    BWEBBL[59] = 1'b0;
end

always @(valid_bwa59) 
begin
    
    DAL[59] = 1'bx;
    BWEBAL[59] = 1'b0;
end

always @(valid_bwb59) 
begin
    disable CLKAOP;
    DBL[59] = 1'bx;
    BWEBBL[59] = 1'b0;
end
always @(valid_da60) 
begin
    
    DAL[60] = 1'bx;
    BWEBAL[60] = 1'b0;
end

always @(valid_db60) 
begin
    disable CLKAOP;
    DBL[60] = 1'bx;
    BWEBBL[60] = 1'b0;
end

always @(valid_bwa60) 
begin
    
    DAL[60] = 1'bx;
    BWEBAL[60] = 1'b0;
end

always @(valid_bwb60) 
begin
    disable CLKAOP;
    DBL[60] = 1'bx;
    BWEBBL[60] = 1'b0;
end
always @(valid_da61) 
begin
    
    DAL[61] = 1'bx;
    BWEBAL[61] = 1'b0;
end

always @(valid_db61) 
begin
    disable CLKAOP;
    DBL[61] = 1'bx;
    BWEBBL[61] = 1'b0;
end

always @(valid_bwa61) 
begin
    
    DAL[61] = 1'bx;
    BWEBAL[61] = 1'b0;
end

always @(valid_bwb61) 
begin
    disable CLKAOP;
    DBL[61] = 1'bx;
    BWEBBL[61] = 1'b0;
end
always @(valid_da62) 
begin
    
    DAL[62] = 1'bx;
    BWEBAL[62] = 1'b0;
end

always @(valid_db62) 
begin
    disable CLKAOP;
    DBL[62] = 1'bx;
    BWEBBL[62] = 1'b0;
end

always @(valid_bwa62) 
begin
    
    DAL[62] = 1'bx;
    BWEBAL[62] = 1'b0;
end

always @(valid_bwb62) 
begin
    disable CLKAOP;
    DBL[62] = 1'bx;
    BWEBBL[62] = 1'b0;
end
always @(valid_da63) 
begin
    
    DAL[63] = 1'bx;
    BWEBAL[63] = 1'b0;
end

always @(valid_db63) 
begin
    disable CLKAOP;
    DBL[63] = 1'bx;
    BWEBBL[63] = 1'b0;
end

always @(valid_bwa63) 
begin
    
    DAL[63] = 1'bx;
    BWEBAL[63] = 1'b0;
end

always @(valid_bwb63) 
begin
    disable CLKAOP;
    DBL[63] = 1'bx;
    BWEBBL[63] = 1'b0;
end
always @(valid_da64) 
begin
    
    DAL[64] = 1'bx;
    BWEBAL[64] = 1'b0;
end

always @(valid_db64) 
begin
    disable CLKAOP;
    DBL[64] = 1'bx;
    BWEBBL[64] = 1'b0;
end

always @(valid_bwa64) 
begin
    
    DAL[64] = 1'bx;
    BWEBAL[64] = 1'b0;
end

always @(valid_bwb64) 
begin
    disable CLKAOP;
    DBL[64] = 1'bx;
    BWEBBL[64] = 1'b0;
end
always @(valid_da65) 
begin
    
    DAL[65] = 1'bx;
    BWEBAL[65] = 1'b0;
end

always @(valid_db65) 
begin
    disable CLKAOP;
    DBL[65] = 1'bx;
    BWEBBL[65] = 1'b0;
end

always @(valid_bwa65) 
begin
    
    DAL[65] = 1'bx;
    BWEBAL[65] = 1'b0;
end

always @(valid_bwb65) 
begin
    disable CLKAOP;
    DBL[65] = 1'bx;
    BWEBBL[65] = 1'b0;
end
always @(valid_da66) 
begin
    
    DAL[66] = 1'bx;
    BWEBAL[66] = 1'b0;
end

always @(valid_db66) 
begin
    disable CLKAOP;
    DBL[66] = 1'bx;
    BWEBBL[66] = 1'b0;
end

always @(valid_bwa66) 
begin
    
    DAL[66] = 1'bx;
    BWEBAL[66] = 1'b0;
end

always @(valid_bwb66) 
begin
    disable CLKAOP;
    DBL[66] = 1'bx;
    BWEBBL[66] = 1'b0;
end
always @(valid_da67) 
begin
    
    DAL[67] = 1'bx;
    BWEBAL[67] = 1'b0;
end

always @(valid_db67) 
begin
    disable CLKAOP;
    DBL[67] = 1'bx;
    BWEBBL[67] = 1'b0;
end

always @(valid_bwa67) 
begin
    
    DAL[67] = 1'bx;
    BWEBAL[67] = 1'b0;
end

always @(valid_bwb67) 
begin
    disable CLKAOP;
    DBL[67] = 1'bx;
    BWEBBL[67] = 1'b0;
end
always @(valid_da68) 
begin
    
    DAL[68] = 1'bx;
    BWEBAL[68] = 1'b0;
end

always @(valid_db68) 
begin
    disable CLKAOP;
    DBL[68] = 1'bx;
    BWEBBL[68] = 1'b0;
end

always @(valid_bwa68) 
begin
    
    DAL[68] = 1'bx;
    BWEBAL[68] = 1'b0;
end

always @(valid_bwb68) 
begin
    disable CLKAOP;
    DBL[68] = 1'bx;
    BWEBBL[68] = 1'b0;
end
always @(valid_da69) 
begin
    
    DAL[69] = 1'bx;
    BWEBAL[69] = 1'b0;
end

always @(valid_db69) 
begin
    disable CLKAOP;
    DBL[69] = 1'bx;
    BWEBBL[69] = 1'b0;
end

always @(valid_bwa69) 
begin
    
    DAL[69] = 1'bx;
    BWEBAL[69] = 1'b0;
end

always @(valid_bwb69) 
begin
    disable CLKAOP;
    DBL[69] = 1'bx;
    BWEBBL[69] = 1'b0;
end
always @(valid_da70) 
begin
    
    DAL[70] = 1'bx;
    BWEBAL[70] = 1'b0;
end

always @(valid_db70) 
begin
    disable CLKAOP;
    DBL[70] = 1'bx;
    BWEBBL[70] = 1'b0;
end

always @(valid_bwa70) 
begin
    
    DAL[70] = 1'bx;
    BWEBAL[70] = 1'b0;
end

always @(valid_bwb70) 
begin
    disable CLKAOP;
    DBL[70] = 1'bx;
    BWEBBL[70] = 1'b0;
end
always @(valid_da71) 
begin
    
    DAL[71] = 1'bx;
    BWEBAL[71] = 1'b0;
end

always @(valid_db71) 
begin
    disable CLKAOP;
    DBL[71] = 1'bx;
    BWEBBL[71] = 1'b0;
end

always @(valid_bwa71) 
begin
    
    DAL[71] = 1'bx;
    BWEBAL[71] = 1'b0;
end

always @(valid_bwb71) 
begin
    disable CLKAOP;
    DBL[71] = 1'bx;
    BWEBBL[71] = 1'b0;
end
always @(valid_da72) 
begin
    
    DAL[72] = 1'bx;
    BWEBAL[72] = 1'b0;
end

always @(valid_db72) 
begin
    disable CLKAOP;
    DBL[72] = 1'bx;
    BWEBBL[72] = 1'b0;
end

always @(valid_bwa72) 
begin
    
    DAL[72] = 1'bx;
    BWEBAL[72] = 1'b0;
end

always @(valid_bwb72) 
begin
    disable CLKAOP;
    DBL[72] = 1'bx;
    BWEBBL[72] = 1'b0;
end
always @(valid_da73) 
begin
    
    DAL[73] = 1'bx;
    BWEBAL[73] = 1'b0;
end

always @(valid_db73) 
begin
    disable CLKAOP;
    DBL[73] = 1'bx;
    BWEBBL[73] = 1'b0;
end

always @(valid_bwa73) 
begin
    
    DAL[73] = 1'bx;
    BWEBAL[73] = 1'b0;
end

always @(valid_bwb73) 
begin
    disable CLKAOP;
    DBL[73] = 1'bx;
    BWEBBL[73] = 1'b0;
end
always @(valid_da74) 
begin
    
    DAL[74] = 1'bx;
    BWEBAL[74] = 1'b0;
end

always @(valid_db74) 
begin
    disable CLKAOP;
    DBL[74] = 1'bx;
    BWEBBL[74] = 1'b0;
end

always @(valid_bwa74) 
begin
    
    DAL[74] = 1'bx;
    BWEBAL[74] = 1'b0;
end

always @(valid_bwb74) 
begin
    disable CLKAOP;
    DBL[74] = 1'bx;
    BWEBBL[74] = 1'b0;
end
always @(valid_da75) 
begin
    
    DAL[75] = 1'bx;
    BWEBAL[75] = 1'b0;
end

always @(valid_db75) 
begin
    disable CLKAOP;
    DBL[75] = 1'bx;
    BWEBBL[75] = 1'b0;
end

always @(valid_bwa75) 
begin
    
    DAL[75] = 1'bx;
    BWEBAL[75] = 1'b0;
end

always @(valid_bwb75) 
begin
    disable CLKAOP;
    DBL[75] = 1'bx;
    BWEBBL[75] = 1'b0;
end
always @(valid_da76) 
begin
    
    DAL[76] = 1'bx;
    BWEBAL[76] = 1'b0;
end

always @(valid_db76) 
begin
    disable CLKAOP;
    DBL[76] = 1'bx;
    BWEBBL[76] = 1'b0;
end

always @(valid_bwa76) 
begin
    
    DAL[76] = 1'bx;
    BWEBAL[76] = 1'b0;
end

always @(valid_bwb76) 
begin
    disable CLKAOP;
    DBL[76] = 1'bx;
    BWEBBL[76] = 1'b0;
end
always @(valid_da77) 
begin
    
    DAL[77] = 1'bx;
    BWEBAL[77] = 1'b0;
end

always @(valid_db77) 
begin
    disable CLKAOP;
    DBL[77] = 1'bx;
    BWEBBL[77] = 1'b0;
end

always @(valid_bwa77) 
begin
    
    DAL[77] = 1'bx;
    BWEBAL[77] = 1'b0;
end

always @(valid_bwb77) 
begin
    disable CLKAOP;
    DBL[77] = 1'bx;
    BWEBBL[77] = 1'b0;
end
always @(valid_da78) 
begin
    
    DAL[78] = 1'bx;
    BWEBAL[78] = 1'b0;
end

always @(valid_db78) 
begin
    disable CLKAOP;
    DBL[78] = 1'bx;
    BWEBBL[78] = 1'b0;
end

always @(valid_bwa78) 
begin
    
    DAL[78] = 1'bx;
    BWEBAL[78] = 1'b0;
end

always @(valid_bwb78) 
begin
    disable CLKAOP;
    DBL[78] = 1'bx;
    BWEBBL[78] = 1'b0;
end
always @(valid_da79) 
begin
    
    DAL[79] = 1'bx;
    BWEBAL[79] = 1'b0;
end

always @(valid_db79) 
begin
    disable CLKAOP;
    DBL[79] = 1'bx;
    BWEBBL[79] = 1'b0;
end

always @(valid_bwa79) 
begin
    
    DAL[79] = 1'bx;
    BWEBAL[79] = 1'b0;
end

always @(valid_bwb79) 
begin
    disable CLKAOP;
    DBL[79] = 1'bx;
    BWEBBL[79] = 1'b0;
end
always @(valid_da80) 
begin
    
    DAL[80] = 1'bx;
    BWEBAL[80] = 1'b0;
end

always @(valid_db80) 
begin
    disable CLKAOP;
    DBL[80] = 1'bx;
    BWEBBL[80] = 1'b0;
end

always @(valid_bwa80) 
begin
    
    DAL[80] = 1'bx;
    BWEBAL[80] = 1'b0;
end

always @(valid_bwb80) 
begin
    disable CLKAOP;
    DBL[80] = 1'bx;
    BWEBBL[80] = 1'b0;
end
always @(valid_da81) 
begin
    
    DAL[81] = 1'bx;
    BWEBAL[81] = 1'b0;
end

always @(valid_db81) 
begin
    disable CLKAOP;
    DBL[81] = 1'bx;
    BWEBBL[81] = 1'b0;
end

always @(valid_bwa81) 
begin
    
    DAL[81] = 1'bx;
    BWEBAL[81] = 1'b0;
end

always @(valid_bwb81) 
begin
    disable CLKAOP;
    DBL[81] = 1'bx;
    BWEBBL[81] = 1'b0;
end
always @(valid_da82) 
begin
    
    DAL[82] = 1'bx;
    BWEBAL[82] = 1'b0;
end

always @(valid_db82) 
begin
    disable CLKAOP;
    DBL[82] = 1'bx;
    BWEBBL[82] = 1'b0;
end

always @(valid_bwa82) 
begin
    
    DAL[82] = 1'bx;
    BWEBAL[82] = 1'b0;
end

always @(valid_bwb82) 
begin
    disable CLKAOP;
    DBL[82] = 1'bx;
    BWEBBL[82] = 1'b0;
end
always @(valid_da83) 
begin
    
    DAL[83] = 1'bx;
    BWEBAL[83] = 1'b0;
end

always @(valid_db83) 
begin
    disable CLKAOP;
    DBL[83] = 1'bx;
    BWEBBL[83] = 1'b0;
end

always @(valid_bwa83) 
begin
    
    DAL[83] = 1'bx;
    BWEBAL[83] = 1'b0;
end

always @(valid_bwb83) 
begin
    disable CLKAOP;
    DBL[83] = 1'bx;
    BWEBBL[83] = 1'b0;
end
always @(valid_da84) 
begin
    
    DAL[84] = 1'bx;
    BWEBAL[84] = 1'b0;
end

always @(valid_db84) 
begin
    disable CLKAOP;
    DBL[84] = 1'bx;
    BWEBBL[84] = 1'b0;
end

always @(valid_bwa84) 
begin
    
    DAL[84] = 1'bx;
    BWEBAL[84] = 1'b0;
end

always @(valid_bwb84) 
begin
    disable CLKAOP;
    DBL[84] = 1'bx;
    BWEBBL[84] = 1'b0;
end
always @(valid_da85) 
begin
    
    DAL[85] = 1'bx;
    BWEBAL[85] = 1'b0;
end

always @(valid_db85) 
begin
    disable CLKAOP;
    DBL[85] = 1'bx;
    BWEBBL[85] = 1'b0;
end

always @(valid_bwa85) 
begin
    
    DAL[85] = 1'bx;
    BWEBAL[85] = 1'b0;
end

always @(valid_bwb85) 
begin
    disable CLKAOP;
    DBL[85] = 1'bx;
    BWEBBL[85] = 1'b0;
end
always @(valid_da86) 
begin
    
    DAL[86] = 1'bx;
    BWEBAL[86] = 1'b0;
end

always @(valid_db86) 
begin
    disable CLKAOP;
    DBL[86] = 1'bx;
    BWEBBL[86] = 1'b0;
end

always @(valid_bwa86) 
begin
    
    DAL[86] = 1'bx;
    BWEBAL[86] = 1'b0;
end

always @(valid_bwb86) 
begin
    disable CLKAOP;
    DBL[86] = 1'bx;
    BWEBBL[86] = 1'b0;
end
always @(valid_da87) 
begin
    
    DAL[87] = 1'bx;
    BWEBAL[87] = 1'b0;
end

always @(valid_db87) 
begin
    disable CLKAOP;
    DBL[87] = 1'bx;
    BWEBBL[87] = 1'b0;
end

always @(valid_bwa87) 
begin
    
    DAL[87] = 1'bx;
    BWEBAL[87] = 1'b0;
end

always @(valid_bwb87) 
begin
    disable CLKAOP;
    DBL[87] = 1'bx;
    BWEBBL[87] = 1'b0;
end
always @(valid_da88) 
begin
    
    DAL[88] = 1'bx;
    BWEBAL[88] = 1'b0;
end

always @(valid_db88) 
begin
    disable CLKAOP;
    DBL[88] = 1'bx;
    BWEBBL[88] = 1'b0;
end

always @(valid_bwa88) 
begin
    
    DAL[88] = 1'bx;
    BWEBAL[88] = 1'b0;
end

always @(valid_bwb88) 
begin
    disable CLKAOP;
    DBL[88] = 1'bx;
    BWEBBL[88] = 1'b0;
end
always @(valid_da89) 
begin
    
    DAL[89] = 1'bx;
    BWEBAL[89] = 1'b0;
end

always @(valid_db89) 
begin
    disable CLKAOP;
    DBL[89] = 1'bx;
    BWEBBL[89] = 1'b0;
end

always @(valid_bwa89) 
begin
    
    DAL[89] = 1'bx;
    BWEBAL[89] = 1'b0;
end

always @(valid_bwb89) 
begin
    disable CLKAOP;
    DBL[89] = 1'bx;
    BWEBBL[89] = 1'b0;
end
always @(valid_da90) 
begin
    
    DAL[90] = 1'bx;
    BWEBAL[90] = 1'b0;
end

always @(valid_db90) 
begin
    disable CLKAOP;
    DBL[90] = 1'bx;
    BWEBBL[90] = 1'b0;
end

always @(valid_bwa90) 
begin
    
    DAL[90] = 1'bx;
    BWEBAL[90] = 1'b0;
end

always @(valid_bwb90) 
begin
    disable CLKAOP;
    DBL[90] = 1'bx;
    BWEBBL[90] = 1'b0;
end
always @(valid_da91) 
begin
    
    DAL[91] = 1'bx;
    BWEBAL[91] = 1'b0;
end

always @(valid_db91) 
begin
    disable CLKAOP;
    DBL[91] = 1'bx;
    BWEBBL[91] = 1'b0;
end

always @(valid_bwa91) 
begin
    
    DAL[91] = 1'bx;
    BWEBAL[91] = 1'b0;
end

always @(valid_bwb91) 
begin
    disable CLKAOP;
    DBL[91] = 1'bx;
    BWEBBL[91] = 1'b0;
end
always @(valid_da92) 
begin
    
    DAL[92] = 1'bx;
    BWEBAL[92] = 1'b0;
end

always @(valid_db92) 
begin
    disable CLKAOP;
    DBL[92] = 1'bx;
    BWEBBL[92] = 1'b0;
end

always @(valid_bwa92) 
begin
    
    DAL[92] = 1'bx;
    BWEBAL[92] = 1'b0;
end

always @(valid_bwb92) 
begin
    disable CLKAOP;
    DBL[92] = 1'bx;
    BWEBBL[92] = 1'b0;
end
always @(valid_da93) 
begin
    
    DAL[93] = 1'bx;
    BWEBAL[93] = 1'b0;
end

always @(valid_db93) 
begin
    disable CLKAOP;
    DBL[93] = 1'bx;
    BWEBBL[93] = 1'b0;
end

always @(valid_bwa93) 
begin
    
    DAL[93] = 1'bx;
    BWEBAL[93] = 1'b0;
end

always @(valid_bwb93) 
begin
    disable CLKAOP;
    DBL[93] = 1'bx;
    BWEBBL[93] = 1'b0;
end
always @(valid_da94) 
begin
    
    DAL[94] = 1'bx;
    BWEBAL[94] = 1'b0;
end

always @(valid_db94) 
begin
    disable CLKAOP;
    DBL[94] = 1'bx;
    BWEBBL[94] = 1'b0;
end

always @(valid_bwa94) 
begin
    
    DAL[94] = 1'bx;
    BWEBAL[94] = 1'b0;
end

always @(valid_bwb94) 
begin
    disable CLKAOP;
    DBL[94] = 1'bx;
    BWEBBL[94] = 1'b0;
end
always @(valid_da95) 
begin
    
    DAL[95] = 1'bx;
    BWEBAL[95] = 1'b0;
end

always @(valid_db95) 
begin
    disable CLKAOP;
    DBL[95] = 1'bx;
    BWEBBL[95] = 1'b0;
end

always @(valid_bwa95) 
begin
    
    DAL[95] = 1'bx;
    BWEBAL[95] = 1'b0;
end

always @(valid_bwb95) 
begin
    disable CLKAOP;
    DBL[95] = 1'bx;
    BWEBBL[95] = 1'b0;
end
always @(valid_da96) 
begin
    
    DAL[96] = 1'bx;
    BWEBAL[96] = 1'b0;
end

always @(valid_db96) 
begin
    disable CLKAOP;
    DBL[96] = 1'bx;
    BWEBBL[96] = 1'b0;
end

always @(valid_bwa96) 
begin
    
    DAL[96] = 1'bx;
    BWEBAL[96] = 1'b0;
end

always @(valid_bwb96) 
begin
    disable CLKAOP;
    DBL[96] = 1'bx;
    BWEBBL[96] = 1'b0;
end
always @(valid_da97) 
begin
    
    DAL[97] = 1'bx;
    BWEBAL[97] = 1'b0;
end

always @(valid_db97) 
begin
    disable CLKAOP;
    DBL[97] = 1'bx;
    BWEBBL[97] = 1'b0;
end

always @(valid_bwa97) 
begin
    
    DAL[97] = 1'bx;
    BWEBAL[97] = 1'b0;
end

always @(valid_bwb97) 
begin
    disable CLKAOP;
    DBL[97] = 1'bx;
    BWEBBL[97] = 1'b0;
end
always @(valid_da98) 
begin
    
    DAL[98] = 1'bx;
    BWEBAL[98] = 1'b0;
end

always @(valid_db98) 
begin
    disable CLKAOP;
    DBL[98] = 1'bx;
    BWEBBL[98] = 1'b0;
end

always @(valid_bwa98) 
begin
    
    DAL[98] = 1'bx;
    BWEBAL[98] = 1'b0;
end

always @(valid_bwb98) 
begin
    disable CLKAOP;
    DBL[98] = 1'bx;
    BWEBBL[98] = 1'b0;
end
always @(valid_da99) 
begin
    
    DAL[99] = 1'bx;
    BWEBAL[99] = 1'b0;
end

always @(valid_db99) 
begin
    disable CLKAOP;
    DBL[99] = 1'bx;
    BWEBBL[99] = 1'b0;
end

always @(valid_bwa99) 
begin
    
    DAL[99] = 1'bx;
    BWEBAL[99] = 1'b0;
end

always @(valid_bwb99) 
begin
    disable CLKAOP;
    DBL[99] = 1'bx;
    BWEBBL[99] = 1'b0;
end
always @(valid_da100) 
begin
    
    DAL[100] = 1'bx;
    BWEBAL[100] = 1'b0;
end

always @(valid_db100) 
begin
    disable CLKAOP;
    DBL[100] = 1'bx;
    BWEBBL[100] = 1'b0;
end

always @(valid_bwa100) 
begin
    
    DAL[100] = 1'bx;
    BWEBAL[100] = 1'b0;
end

always @(valid_bwb100) 
begin
    disable CLKAOP;
    DBL[100] = 1'bx;
    BWEBBL[100] = 1'b0;
end
always @(valid_da101) 
begin
    
    DAL[101] = 1'bx;
    BWEBAL[101] = 1'b0;
end

always @(valid_db101) 
begin
    disable CLKAOP;
    DBL[101] = 1'bx;
    BWEBBL[101] = 1'b0;
end

always @(valid_bwa101) 
begin
    
    DAL[101] = 1'bx;
    BWEBAL[101] = 1'b0;
end

always @(valid_bwb101) 
begin
    disable CLKAOP;
    DBL[101] = 1'bx;
    BWEBBL[101] = 1'b0;
end
always @(valid_da102) 
begin
    
    DAL[102] = 1'bx;
    BWEBAL[102] = 1'b0;
end

always @(valid_db102) 
begin
    disable CLKAOP;
    DBL[102] = 1'bx;
    BWEBBL[102] = 1'b0;
end

always @(valid_bwa102) 
begin
    
    DAL[102] = 1'bx;
    BWEBAL[102] = 1'b0;
end

always @(valid_bwb102) 
begin
    disable CLKAOP;
    DBL[102] = 1'bx;
    BWEBBL[102] = 1'b0;
end
always @(valid_da103) 
begin
    
    DAL[103] = 1'bx;
    BWEBAL[103] = 1'b0;
end

always @(valid_db103) 
begin
    disable CLKAOP;
    DBL[103] = 1'bx;
    BWEBBL[103] = 1'b0;
end

always @(valid_bwa103) 
begin
    
    DAL[103] = 1'bx;
    BWEBAL[103] = 1'b0;
end

always @(valid_bwb103) 
begin
    disable CLKAOP;
    DBL[103] = 1'bx;
    BWEBBL[103] = 1'b0;
end
always @(valid_da104) 
begin
    
    DAL[104] = 1'bx;
    BWEBAL[104] = 1'b0;
end

always @(valid_db104) 
begin
    disable CLKAOP;
    DBL[104] = 1'bx;
    BWEBBL[104] = 1'b0;
end

always @(valid_bwa104) 
begin
    
    DAL[104] = 1'bx;
    BWEBAL[104] = 1'b0;
end

always @(valid_bwb104) 
begin
    disable CLKAOP;
    DBL[104] = 1'bx;
    BWEBBL[104] = 1'b0;
end
always @(valid_da105) 
begin
    
    DAL[105] = 1'bx;
    BWEBAL[105] = 1'b0;
end

always @(valid_db105) 
begin
    disable CLKAOP;
    DBL[105] = 1'bx;
    BWEBBL[105] = 1'b0;
end

always @(valid_bwa105) 
begin
    
    DAL[105] = 1'bx;
    BWEBAL[105] = 1'b0;
end

always @(valid_bwb105) 
begin
    disable CLKAOP;
    DBL[105] = 1'bx;
    BWEBBL[105] = 1'b0;
end
always @(valid_da106) 
begin
    
    DAL[106] = 1'bx;
    BWEBAL[106] = 1'b0;
end

always @(valid_db106) 
begin
    disable CLKAOP;
    DBL[106] = 1'bx;
    BWEBBL[106] = 1'b0;
end

always @(valid_bwa106) 
begin
    
    DAL[106] = 1'bx;
    BWEBAL[106] = 1'b0;
end

always @(valid_bwb106) 
begin
    disable CLKAOP;
    DBL[106] = 1'bx;
    BWEBBL[106] = 1'b0;
end
always @(valid_da107) 
begin
    
    DAL[107] = 1'bx;
    BWEBAL[107] = 1'b0;
end

always @(valid_db107) 
begin
    disable CLKAOP;
    DBL[107] = 1'bx;
    BWEBBL[107] = 1'b0;
end

always @(valid_bwa107) 
begin
    
    DAL[107] = 1'bx;
    BWEBAL[107] = 1'b0;
end

always @(valid_bwb107) 
begin
    disable CLKAOP;
    DBL[107] = 1'bx;
    BWEBBL[107] = 1'b0;
end
always @(valid_da108) 
begin
    
    DAL[108] = 1'bx;
    BWEBAL[108] = 1'b0;
end

always @(valid_db108) 
begin
    disable CLKAOP;
    DBL[108] = 1'bx;
    BWEBBL[108] = 1'b0;
end

always @(valid_bwa108) 
begin
    
    DAL[108] = 1'bx;
    BWEBAL[108] = 1'b0;
end

always @(valid_bwb108) 
begin
    disable CLKAOP;
    DBL[108] = 1'bx;
    BWEBBL[108] = 1'b0;
end
always @(valid_da109) 
begin
    
    DAL[109] = 1'bx;
    BWEBAL[109] = 1'b0;
end

always @(valid_db109) 
begin
    disable CLKAOP;
    DBL[109] = 1'bx;
    BWEBBL[109] = 1'b0;
end

always @(valid_bwa109) 
begin
    
    DAL[109] = 1'bx;
    BWEBAL[109] = 1'b0;
end

always @(valid_bwb109) 
begin
    disable CLKAOP;
    DBL[109] = 1'bx;
    BWEBBL[109] = 1'b0;
end
always @(valid_da110) 
begin
    
    DAL[110] = 1'bx;
    BWEBAL[110] = 1'b0;
end

always @(valid_db110) 
begin
    disable CLKAOP;
    DBL[110] = 1'bx;
    BWEBBL[110] = 1'b0;
end

always @(valid_bwa110) 
begin
    
    DAL[110] = 1'bx;
    BWEBAL[110] = 1'b0;
end

always @(valid_bwb110) 
begin
    disable CLKAOP;
    DBL[110] = 1'bx;
    BWEBBL[110] = 1'b0;
end
always @(valid_da111) 
begin
    
    DAL[111] = 1'bx;
    BWEBAL[111] = 1'b0;
end

always @(valid_db111) 
begin
    disable CLKAOP;
    DBL[111] = 1'bx;
    BWEBBL[111] = 1'b0;
end

always @(valid_bwa111) 
begin
    
    DAL[111] = 1'bx;
    BWEBAL[111] = 1'b0;
end

always @(valid_bwb111) 
begin
    disable CLKAOP;
    DBL[111] = 1'bx;
    BWEBBL[111] = 1'b0;
end
always @(valid_da112) 
begin
    
    DAL[112] = 1'bx;
    BWEBAL[112] = 1'b0;
end

always @(valid_db112) 
begin
    disable CLKAOP;
    DBL[112] = 1'bx;
    BWEBBL[112] = 1'b0;
end

always @(valid_bwa112) 
begin
    
    DAL[112] = 1'bx;
    BWEBAL[112] = 1'b0;
end

always @(valid_bwb112) 
begin
    disable CLKAOP;
    DBL[112] = 1'bx;
    BWEBBL[112] = 1'b0;
end
always @(valid_da113) 
begin
    
    DAL[113] = 1'bx;
    BWEBAL[113] = 1'b0;
end

always @(valid_db113) 
begin
    disable CLKAOP;
    DBL[113] = 1'bx;
    BWEBBL[113] = 1'b0;
end

always @(valid_bwa113) 
begin
    
    DAL[113] = 1'bx;
    BWEBAL[113] = 1'b0;
end

always @(valid_bwb113) 
begin
    disable CLKAOP;
    DBL[113] = 1'bx;
    BWEBBL[113] = 1'b0;
end
always @(valid_da114) 
begin
    
    DAL[114] = 1'bx;
    BWEBAL[114] = 1'b0;
end

always @(valid_db114) 
begin
    disable CLKAOP;
    DBL[114] = 1'bx;
    BWEBBL[114] = 1'b0;
end

always @(valid_bwa114) 
begin
    
    DAL[114] = 1'bx;
    BWEBAL[114] = 1'b0;
end

always @(valid_bwb114) 
begin
    disable CLKAOP;
    DBL[114] = 1'bx;
    BWEBBL[114] = 1'b0;
end
always @(valid_da115) 
begin
    
    DAL[115] = 1'bx;
    BWEBAL[115] = 1'b0;
end

always @(valid_db115) 
begin
    disable CLKAOP;
    DBL[115] = 1'bx;
    BWEBBL[115] = 1'b0;
end

always @(valid_bwa115) 
begin
    
    DAL[115] = 1'bx;
    BWEBAL[115] = 1'b0;
end

always @(valid_bwb115) 
begin
    disable CLKAOP;
    DBL[115] = 1'bx;
    BWEBBL[115] = 1'b0;
end
always @(valid_da116) 
begin
    
    DAL[116] = 1'bx;
    BWEBAL[116] = 1'b0;
end

always @(valid_db116) 
begin
    disable CLKAOP;
    DBL[116] = 1'bx;
    BWEBBL[116] = 1'b0;
end

always @(valid_bwa116) 
begin
    
    DAL[116] = 1'bx;
    BWEBAL[116] = 1'b0;
end

always @(valid_bwb116) 
begin
    disable CLKAOP;
    DBL[116] = 1'bx;
    BWEBBL[116] = 1'b0;
end
always @(valid_da117) 
begin
    
    DAL[117] = 1'bx;
    BWEBAL[117] = 1'b0;
end

always @(valid_db117) 
begin
    disable CLKAOP;
    DBL[117] = 1'bx;
    BWEBBL[117] = 1'b0;
end

always @(valid_bwa117) 
begin
    
    DAL[117] = 1'bx;
    BWEBAL[117] = 1'b0;
end

always @(valid_bwb117) 
begin
    disable CLKAOP;
    DBL[117] = 1'bx;
    BWEBBL[117] = 1'b0;
end
always @(valid_da118) 
begin
    
    DAL[118] = 1'bx;
    BWEBAL[118] = 1'b0;
end

always @(valid_db118) 
begin
    disable CLKAOP;
    DBL[118] = 1'bx;
    BWEBBL[118] = 1'b0;
end

always @(valid_bwa118) 
begin
    
    DAL[118] = 1'bx;
    BWEBAL[118] = 1'b0;
end

always @(valid_bwb118) 
begin
    disable CLKAOP;
    DBL[118] = 1'bx;
    BWEBBL[118] = 1'b0;
end
always @(valid_da119) 
begin
    
    DAL[119] = 1'bx;
    BWEBAL[119] = 1'b0;
end

always @(valid_db119) 
begin
    disable CLKAOP;
    DBL[119] = 1'bx;
    BWEBBL[119] = 1'b0;
end

always @(valid_bwa119) 
begin
    
    DAL[119] = 1'bx;
    BWEBAL[119] = 1'b0;
end

always @(valid_bwb119) 
begin
    disable CLKAOP;
    DBL[119] = 1'bx;
    BWEBBL[119] = 1'b0;
end
always @(valid_da120) 
begin
    
    DAL[120] = 1'bx;
    BWEBAL[120] = 1'b0;
end

always @(valid_db120) 
begin
    disable CLKAOP;
    DBL[120] = 1'bx;
    BWEBBL[120] = 1'b0;
end

always @(valid_bwa120) 
begin
    
    DAL[120] = 1'bx;
    BWEBAL[120] = 1'b0;
end

always @(valid_bwb120) 
begin
    disable CLKAOP;
    DBL[120] = 1'bx;
    BWEBBL[120] = 1'b0;
end
always @(valid_da121) 
begin
    
    DAL[121] = 1'bx;
    BWEBAL[121] = 1'b0;
end

always @(valid_db121) 
begin
    disable CLKAOP;
    DBL[121] = 1'bx;
    BWEBBL[121] = 1'b0;
end

always @(valid_bwa121) 
begin
    
    DAL[121] = 1'bx;
    BWEBAL[121] = 1'b0;
end

always @(valid_bwb121) 
begin
    disable CLKAOP;
    DBL[121] = 1'bx;
    BWEBBL[121] = 1'b0;
end
always @(valid_da122) 
begin
    
    DAL[122] = 1'bx;
    BWEBAL[122] = 1'b0;
end

always @(valid_db122) 
begin
    disable CLKAOP;
    DBL[122] = 1'bx;
    BWEBBL[122] = 1'b0;
end

always @(valid_bwa122) 
begin
    
    DAL[122] = 1'bx;
    BWEBAL[122] = 1'b0;
end

always @(valid_bwb122) 
begin
    disable CLKAOP;
    DBL[122] = 1'bx;
    BWEBBL[122] = 1'b0;
end
always @(valid_da123) 
begin
    
    DAL[123] = 1'bx;
    BWEBAL[123] = 1'b0;
end

always @(valid_db123) 
begin
    disable CLKAOP;
    DBL[123] = 1'bx;
    BWEBBL[123] = 1'b0;
end

always @(valid_bwa123) 
begin
    
    DAL[123] = 1'bx;
    BWEBAL[123] = 1'b0;
end

always @(valid_bwb123) 
begin
    disable CLKAOP;
    DBL[123] = 1'bx;
    BWEBBL[123] = 1'b0;
end
always @(valid_da124) 
begin
    
    DAL[124] = 1'bx;
    BWEBAL[124] = 1'b0;
end

always @(valid_db124) 
begin
    disable CLKAOP;
    DBL[124] = 1'bx;
    BWEBBL[124] = 1'b0;
end

always @(valid_bwa124) 
begin
    
    DAL[124] = 1'bx;
    BWEBAL[124] = 1'b0;
end

always @(valid_bwb124) 
begin
    disable CLKAOP;
    DBL[124] = 1'bx;
    BWEBBL[124] = 1'b0;
end
always @(valid_da125) 
begin
    
    DAL[125] = 1'bx;
    BWEBAL[125] = 1'b0;
end

always @(valid_db125) 
begin
    disable CLKAOP;
    DBL[125] = 1'bx;
    BWEBBL[125] = 1'b0;
end

always @(valid_bwa125) 
begin
    
    DAL[125] = 1'bx;
    BWEBAL[125] = 1'b0;
end

always @(valid_bwb125) 
begin
    disable CLKAOP;
    DBL[125] = 1'bx;
    BWEBBL[125] = 1'b0;
end
always @(valid_da126) 
begin
    
    DAL[126] = 1'bx;
    BWEBAL[126] = 1'b0;
end

always @(valid_db126) 
begin
    disable CLKAOP;
    DBL[126] = 1'bx;
    BWEBBL[126] = 1'b0;
end

always @(valid_bwa126) 
begin
    
    DAL[126] = 1'bx;
    BWEBAL[126] = 1'b0;
end

always @(valid_bwb126) 
begin
    disable CLKAOP;
    DBL[126] = 1'bx;
    BWEBBL[126] = 1'b0;
end
always @(valid_da127) 
begin
    
    DAL[127] = 1'bx;
    BWEBAL[127] = 1'b0;
end

always @(valid_db127) 
begin
    disable CLKAOP;
    DBL[127] = 1'bx;
    BWEBBL[127] = 1'b0;
end

always @(valid_bwa127) 
begin
    
    DAL[127] = 1'bx;
    BWEBAL[127] = 1'b0;
end

always @(valid_bwb127) 
begin
    disable CLKAOP;
    DBL[127] = 1'bx;
    BWEBBL[127] = 1'b0;
end

always @(valid_cea) 
begin
    
    #0.002;
    BWEBAL = {N{1'b0}};
    AAL = {M{1'bx}};
    if(bAWT !== 1'b1) begin
      bQA = #0.01 {N{1'bx}};
    end
end

always @(valid_ceb) 
begin
    
    #0.002;
    BWEBBL = {N{1'b0}};
    ABL = {M{1'bx}};
    if(bAWT !== 1'b1) begin
      bQB = #0.01 {N{1'bx}};
    end
end

always @(valid_wea) 
begin
    #0.002;
    BWEBAL = {N{1'b0}};
    AAL = {M{1'bx}};
    if(bAWT !== 1'b1) begin
      bQA = #0.01 {N{1'bx}};
    end
end
 
always @(valid_web) 
begin
    #0.002;
    BWEBBL = {N{1'b0}};
    ABL = {M{1'bx}};
    if(bAWT !== 1'b1) begin
      bQB = #0.01 {N{1'bx}};
    end
end

`endif

// Task for printing the memory between specified addresses..
task printMemoryFromTo;     
    input [M - 1:0] from;   // memory content are printed, start from this address.
    input [M - 1:0] to;     // memory content are printed, end at this address.
    begin 
        MX.printMemoryFromTo(from, to);
    end 
endtask

// Task for printing entire memory, including normal array and redundancy array.
task printMemory;   
    begin
        MX.printMemory;
    end
endtask

task xMemoryAll;   
    begin
       MX.xMemoryAll;  
    end
endtask

task zeroMemoryAll;   
    begin
       MX.zeroMemoryAll;   
    end
endtask

// Task for Loading a perdefined set of data from an external file.
task preloadData;   
    input [256*8:1] infile;  // Max 256 character File Name
    begin
        MX.preloadData(infile);  
    end
endtask

TSDN28HPCPUHDB32X128M4MWA_Int_Array #(2,2,W,N,M,MES_ALL) MX (.D({DAL,DBL}),.BW({BWEBAL,BWEBBL}),
         .AW({AAL,ABL}),.EN(EN),.AAR(AAL),.ABR(ABL),.RDA(RDA),.RDB(RDB),.QA(QAL),.QB(QBL));
 
endmodule

    `disable_portfaults
    `nosuppress_faults
    `endcelldefine

    /*
       The module ports are parameterizable vectors.
    */
    module TSDN28HPCPUHDB32X128M4MWA_Int_Array (D, BW, AW, EN, AAR, ABR, RDA, RDB, QA, QB);
    parameter Nread = 2;   // Number of Read Ports
    parameter Nwrite = 2;  // Number of Write Ports
    parameter Nword = 2;   // Number of Words
    parameter Ndata = 1;   // Number of Data Bits / Word
    parameter Naddr = 1;   // Number of Address Bits / Word
    parameter MES_ALL = "ON";
    parameter dly = 0.000;
    // Cannot define inputs/outputs as memories
    input  [Ndata*Nwrite-1:0] D;  // Data Word(s)
    input  [Ndata*Nwrite-1:0] BW; // Negative Bit Write Enable
    input  [Naddr*Nwrite-1:0] AW; // Write Address(es)
    input  EN;                    // Positive Write Enable
    input  RDA;                    // Positive Write Enable
    input  RDB;                    // Positive Write Enable
    input  [Naddr-1:0] AAR;  // Read Address(es)
    input  [Naddr-1:0] ABR;  // Read Address(es)
    output [Ndata-1:0] QA;   // Output Data Word(s)
    output [Ndata-1:0] QB;   // Output Data Word(s)
    reg    [Ndata-1:0] QA;
    reg    [Ndata-1:0] QB;
    reg [Ndata-1:0] mem [Nword-1:0];
    reg [Ndata-1:0] mem_fault [Nword-1:0];
    reg chgmem;            // Toggled when write to mem
    reg [Nwrite-1:0] wwe;  // Positive Word Write Enable for each Port
    reg we;                // Positive Write Enable for all Ports
    integer waddr[Nwrite-1:0]; // Write Address for each Enabled Port
    integer address;       // Current address
    reg [Naddr-1:0] abuf;  // Address of current port
    reg [Ndata-1:0] dbuf;  // Data for current port
    reg [Naddr-1:0] abuf_ra;  // Address of current port
    reg [Ndata-1:0] dbuf_ra;  // Data for current port
    reg [Naddr-1:0] abuf_rb;  // Address of current port
    reg [Ndata-1:0] dbuf_rb;  // Data for current port
    reg [Ndata-1:0] bwbuf; // Bit Write enable for current port
    reg dup;               // Is the address a duplicate?
    integer log;           // Log file descriptor
    integer ip, ip2, ib, iba_r, ibb_r, iw, iwb, i; // Vector indices


    initial 
    begin
        if(log[0] === 1'bx)
            log = 1;
        chgmem = 1'b0;
    end


    always @(D or BW or AW or EN) 
    begin: WRITE //{
        if(EN !== 1'b0) 
        begin //{ Possible write
            we = 1'b0;
            // Mark any write enabled ports & get write addresses
            for (ip = 0 ; ip < Nwrite ; ip = ip + 1) 
            begin //{
                ib = ip * Ndata;
                iw = ib + Ndata;
                while (ib < iw && BW[ib] === 1'b1)
                begin
                    ib = ib + 1;
                end
                if(ib == iw)
                begin
                    wwe[ip] = 1'b0;
                end
                else 
                begin //{ ip write enabled
                    iw = ip * Naddr;
                    for (ib = 0 ; ib < Naddr ; ib = ib + 1) 
                    begin //{
                        abuf[ib] = AW[iw+ib];
                        if(abuf[ib] !== 1'b0 && abuf[ib] !== 1'b1)
                        begin
                            ib = Naddr;
                        end
                    end //}
                    if(ib == Naddr) 
                    begin //{
                        if(abuf < Nword) 
                        begin //{ Valid address
                            waddr[ip] = abuf;
                            wwe[ip] = 1'b1;
                            if(we == 1'b0) 
                            begin
                                chgmem = ~chgmem;
                                we = EN;
                            end
                        end //}
                        else 
                        begin //{ Out of range address
                             wwe[ip] = 1'b0;
                             if( MES_ALL=="ON" && $realtime != 0)
                                  $fdisplay (log,
                                             "\nWarning! Int_Array instance, %m:",
                                             "\n\t Port %0d", ip,
                                             " write address x'%0h'", abuf,
                                             " out of range at time %t.", $realtime,
                                             "\n\t Port %0d data not written to memory.", ip);
                        end //}
                    end //}
                    else 
                    begin //{ unknown write address
                        for (ib = 0 ; ib < Ndata ; ib = ib + 1)
                        begin
                            dbuf[ib] = 1'bx;
                        end
                        for (iw = 0 ; iw < Nword ; iw = iw + 1)
                        begin
                            mem[iw] = dbuf;
                        end
                        chgmem = ~chgmem;
                        disable WRITE;
                    end //}
                end //} ip write enabled
            end //} for ip
            if(we === 1'b1) 
            begin //{ active write enable
                for (ip = 0 ; ip < Nwrite ; ip = ip + 1) 
                begin //{
                    if(wwe[ip]) 
                    begin //{ write enabled bits of write port ip
                        address = waddr[ip];
                        dbuf = mem[address];
                        iw = ip * Ndata;
                        for (ib = 0 ; ib < Ndata ; ib = ib + 1) 
                        begin //{
                            iwb = iw + ib;
                            if(BW[iwb] === 1'b0)
                            begin
                                dbuf[ib] = D[iwb];
                            end
                            else
                            if(BW[iwb] !== 1'b1)
                            begin
                                dbuf[ib] = 1'bx;
                            end
                        end //}
                        // Check other ports for same address &
                        // common write enable bits active
                        dup = 0;
                        for (ip2 = ip + 1 ; ip2 < Nwrite ; ip2 = ip2 + 1) 
                        begin //{
                            if(wwe[ip2] && address == waddr[ip2]) 
                            begin //{
                                // initialize bwbuf if first dup
                                if(!dup) 
                                begin
                                    for (ib = 0 ; ib < Ndata ; ib = ib + 1)
                                    begin
                                        bwbuf[ib] = BW[iw+ib];
                                    end
                                    dup = 1;
                                end
                                iw = ip2 * Ndata;
                                for (ib = 0 ; ib < Ndata ; ib = ib + 1) 
                                begin //{
                                    iwb = iw + ib;
                                    // New: Always set X if BW X
                                    if(BW[iwb] === 1'b0) 
                                    begin //{
                                        if(bwbuf[ib] !== 1'b1) 
                                        begin
                                            if(D[iwb] !== dbuf[ib])
                                            begin
                                                dbuf[ib] = 1'bx;
                                            end
                                        end
                                        else 
                                        begin
                                            dbuf[ib] = D[iwb];
                                            bwbuf[ib] = 1'b0;
                                        end
                                    end //}
                                    else if(BW[iwb] !== 1'b1) 
                                    begin
                                        dbuf[ib] = 1'bx;
                                        bwbuf[ib] = 1'bx;
                                    end
                                end //} for each bit
                                wwe[ip2] = 1'b0;
                            end //} Port ip2 address matches port ip
                        end //} for each port beyond ip (ip2=ip+1)
                        // Write dbuf to memory
                        mem[address] = dbuf;
                    end //} wwe[ip] - write port ip enabled
                end //} for each write port ip
            end //} active write enable
            else if(we !== 1'b0) 
            begin //{ unknown write enable
                for (ip = 0 ; ip < Nwrite ; ip = ip + 1) 
                begin //{
                    if(wwe[ip]) 
                    begin //{ write X to enabled bits of write port ip
                        address = waddr[ip];
                        dbuf = mem[address];
                        iw = ip * Ndata;
                        for (ib = 0 ; ib < Ndata ; ib = ib + 1) 
                        begin //{ 
                            if(BW[iw+ib] !== 1'b1)
                            begin
                                dbuf[ib] = 1'bx;
                            end
                        end //} 
                        mem[address] = dbuf;
                        if( MES_ALL=="ON" && $realtime != 0)
                            $fdisplay (log,
                                       "\nWarning! Int_Array instance, %m:",
                                       "\n\t Enable pin unknown at time %t.", $realtime,
                                       "\n\t Enabled bits at port %0d", ip,
                                       " write address x'%0h' set unknown.", address);
                    end //} wwe[ip] - write port ip enabled
                end //} for each write port ip
            end //} unknown write enable
        end //} possible write (EN != 0)
    end //} always @(D or BW or AW or EN)


    // Read memory
    always @(AAR or RDA) 
    begin //{
        for (iba_r = 0 ; iba_r < Naddr ; iba_r = iba_r + 1) 
        begin
            abuf_ra[iba_r] = AAR[iba_r];
            if(abuf_ra[iba_r] !== 0 && abuf_ra[iba_r] !== 1)
            begin
                iba_r = Naddr;
            end
        end
        if(iba_r == Naddr && abuf_ra < Nword) 
        begin //{ Read valid address
    `ifdef TSMC_INITIALIZE_FAULT
            dbuf_ra = mem[abuf_ra] ^ mem_fault[abuf_ra];
    `else
            dbuf_ra = mem[abuf_ra];
    `endif
            for (iba_r = 0 ; iba_r < Ndata ; iba_r = iba_r + 1) 
            begin
                if(QA[iba_r] == dbuf_ra[iba_r])
                begin
                    QA[iba_r] <= #(dly) dbuf_ra[iba_r];
                end
                else 
                begin
                    QA[iba_r] <= #(dly) dbuf_ra[iba_r];
                end // else
            end // for
        end //} valid address
        else 
        begin //{ Invalid address
            if(iba_r <= Naddr) begin 
                if( MES_ALL=="ON" && $realtime != 0)
                    $fwrite (log, "\nWarning! Int_Array instance, %m:",
                         "\n\t Port A read address");
                if( MES_ALL=="ON" && $realtime != 0)
                    $fwrite (log, " x'%0h' out of range", abuf_ra);
                if( MES_ALL=="ON" && $realtime != 0)
                    $fdisplay (log,
                           " at time %t.", $realtime,
                           "\n\t Port A outputs set to unknown.");
            end   
            
            for (iba_r = 0 ; iba_r < Ndata ; iba_r = iba_r + 1)
                QA[iba_r] <= #(dly) 1'bx;
        end //} invalid address
    end //} always @(chgmem or AR)

    // Read memory
    always @(ABR or RDB) 
    begin //{
        for (ibb_r = 0 ; ibb_r < Naddr ; ibb_r = ibb_r + 1) 
        begin
            abuf_rb[ibb_r] = ABR[ibb_r];
            if(abuf_rb[ibb_r] !== 0 && abuf_rb[ibb_r] !== 1)
            begin
                ibb_r = Naddr;
            end
        end
        if(ibb_r == Naddr && abuf_rb < Nword) 
        begin //{ Read valid address
    `ifdef TSMC_INITIALIZE_FAULT
            dbuf_rb = mem[abuf_rb] ^ mem_fault[abuf_rb];
    `else
            dbuf_rb = mem[abuf_rb];
    `endif
            for (ibb_r = 0 ; ibb_r < Ndata ; ibb_r = ibb_r + 1) 
            begin
                if(QB[ibb_r] == dbuf_rb[ibb_r])
                begin
                    QB[ibb_r] <= #(dly) dbuf_rb[ibb_r];
                end
                else 
                begin
                    QB[ibb_r] <= #(dly) dbuf_rb[ibb_r];
                end // else
            end // for
        end //} valid address
        else 
        begin //{ Invalid address
            if(ibb_r <= Naddr) begin 
                if( MES_ALL=="ON" && $realtime != 0)
                    $fwrite (log, "\nWarning! Int_Array instance, %m:",
                         "\n\t Port B read address");
                if( MES_ALL=="ON" && $realtime != 0)
                    $fwrite (log, " x'%0h' out of range", abuf_rb);
                if( MES_ALL=="ON" && $realtime != 0)
                    $fdisplay (log,
                           " at time %t.", $realtime,
                           "\n\t Port B outputs set to unknown.");
            end   
            for (ibb_r = 0 ; ibb_r < Ndata ; ibb_r = ibb_r + 1)
                QB[ibb_r] <= #(dly) 1'bx;
        end //} invalid address
    end //} always @(chgmem or AR)


    // Task for loading contents of a memory
    task preloadData;   
        input [256*8:1] infile;  // Max 256 character File Name
        begin
            $display ("%m: Reading file, %0s, into the register file", infile);
    `ifdef TSMC_INITIALIZE_FORMAT_BINARY
            $readmemb (infile, mem, 0, Nword-1);
    `else
            $readmemh (infile, mem, 0, Nword-1);
    `endif
        end
    endtask

    // Task for displaying contents of a memory
    task printMemoryFromTo;   
        input [Naddr - 1:0] from;   // memory content are printed, start from this address.
        input [Naddr - 1:0] to;     // memory content are printed, end at this address.
        integer i;
    begin //{
        $display ("\n%m: Memory content dump");
        if(from < 0 || from > to || to >= Nword)
        begin
            $display ("Error! Invalid address range (%0d, %0d).", from, to,
                      "\nUsage: %m (from, to);",
                      "\n       where from >= 0 and to <= %0d.", Nword-1);
        end
        else 
        begin
            $display ("\n    Address\tValue");
            for (i = from ; i <= to ; i = i + 1)
                $display ("%d\t%b", i, mem[i]);
        end
    end //}
    endtask //}

    // Task for printing entire memory, including normal array and redundancy array.
    task printMemory;   
        integer i;
        begin
            $display ("Dumping register file...");
            $display("@    Address, content-----");
            for (i = 0; i < Nword; i = i + 1) begin
                $display("@%d, %b", i, mem[i]);
            end 
        end
    endtask

    task xMemoryAll;   
        begin
           for (ib = 0 ; ib < Ndata ; ib = ib + 1)
              dbuf[ib] = 1'bx;
           for (iw = 0 ; iw < Nword ; iw = iw + 1)
              mem[iw] = dbuf; 
        end
    endtask

    task zeroMemoryAll;   
        begin
           for (ib = 0 ; ib < Ndata ; ib = ib + 1)
              dbuf[ib] = 1'b0;
           for (iw = 0 ; iw < Nword ; iw = iw + 1)
              mem[iw] = dbuf; 
        end
    endtask
    endmodule



