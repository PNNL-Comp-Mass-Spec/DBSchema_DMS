/****** Object:  Table [T_Analysis_Tool] ******/
/****** RowCount: 92 ******/
/****** Columns: AJT_toolID, AJT_toolName, AJT_toolBasename, AJT_paramFileType, AJT_parmFileStoragePath, AJT_parmFileStoragePathLocal, AJT_defaultSettingsFileName, AJT_resultType, AJT_autoScanFolderFlag, AJT_active, AJT_searchEngineInputFileFormats, AJT_orgDbReqd, AJT_extractionRequired, x_Unused_AJT_toolTag, AJT_description, Use_SpecialProcWaiting, SettingsFileRequired, ParamFileRequired ******/
INSERT INTO [T_Analysis_Tool] VALUES (0,'(none)','(none)',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (1,'Sequest','Sequest',1000,'\\gigasax\DMS_Parameter_Files\Sequest','G:\DMS_Parameter_Files\Sequest','LCQDefSettings.txt','Peptide_Hit','no ',0,'Individual_DTA',1,'Y','Sequest','Search MS/MS spectra with Sequest',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (2,'ICR2LS','ICR2LS',1003,'\\gigasax\DMS_Parameter_Files\ICR2LS','G:\DMS_Parameter_Files\ICR2LS','FTICRDefSettings.txt','HMMA_Peak','yes',1,'(na)',0,'N','ICR2LS',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (3,'TurboSequest','Sequest',1000,'\\gigasax\DMS_Parameter_Files\Sequest','G:\DMS_Parameter_Files\Sequest','LCQDefSettings.txt','Peptide_Hit','yes',0,'Individual_DTA',1,'Y','Sequest',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (4,'TIC_ICR','ICR2LS',1003,'\\gigasax\DMS_Parameter_Files\ICR2LS','G:\DMS_Parameter_Files\ICR2LS','(na)','TIC','yes',0,'(na)',0,'N','ICR2LS',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (5,'TIC_LCQ','TIC_LCQ',1,'\\gigasax\DMS_Parameter_Files\Sequest','G:\DMS_Parameter_Files\Sequest','(na)','TIC','yes',0,'(na)',0,'N','TIC_LCQ',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (6,'QTOFSequest','Sequest',1000,'\\gigasax\DMS_Parameter_Files\Sequest','G:\DMS_Parameter_Files\Sequest','LCQDefSettings.txt','Peptide_Hit','yes',0,'(na)',1,'Y','Sequest',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (7,'QTOFPek','QTOFPek',1001,'\\gigasax\DMS_Parameter_Files\QTOFPek','G:\DMS_Parameter_Files\QTOFPek','QTOFPekDefSettings.txt','HMMA_Peak','yes',0,'(na)',0,'N','QTOFPek',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (8,'DeNovoID','DeNovoID',1002,'\\gigasax\DMS_Parameter_Files\DeNovoPeak','G:\DMS_Parameter_Files\DeNovoPeak','DeNovo_Default.xml',null,'yes',0,'(na)',1,'N','DeNovoID',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (9,'AgilentSequest','Sequest',1000,'\\gigasax\DMS_Parameter_Files\Sequest','G:\DMS_Parameter_Files\Sequest','AgilentDefSettings.xml','Peptide_Hit','yes',0,'(na)',1,'Y','Sequest',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (10,'MLynxPek','MLynxPek',1004,'\\gigasax\DMS_Parameter_Files\MLynxPek','G:\DMS_Parameter_Files\MLynxPek','MMTofDefSettings.xml','HMMA_Peak','yes',0,'(na)',0,'N','MLynxPek',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (11,'AgilentTOFPek','AgilentTOFPek',1005,'\\gigasax\DMS_Parameter_Files\AgilentTOFPek','G:\DMS_Parameter_Files\AgilentTOFPek','AgTofDefSettings.xml','HMMA_Peak','yes',0,'(na)',0,'N','AgilentTOFPek',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (12,'LTQ_FTPek','LTQ_FTPek',1006,'\\gigasax\DMS_Parameter_Files\LTQ_FTPek','G:\DMS_Parameter_Files\LTQ_FTPek','LTQ_FTDefSettings.txt','HMMA_Peak','yes',1,'(na)',0,'N','ICR2LS',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (13,'MASIC_Finnigan','MASIC',1007,'\\gigasax\DMS_Parameter_Files\MASIC','G:\DMS_Parameter_Files\MASIC','(na)','SIC','yes',1,'(na)',0,'N','MASIC','Extract Thermo Instrument Data including peak intensities',0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (14,'MASIC_Agilent','MASIC',1007,'\\gigasax\DMS_Parameter_Files\MASIC','G:\DMS_Parameter_Files\MASIC','(na)','SIC','yes',0,'(na)',0,'N','MASIC',null,0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (15,'XTandem','XTandem',1008,'\\gigasax\DMS_Parameter_Files\XTandem','G:\DMS_Parameter_Files\XTandem','??','XT_Peptide_Hit','no ',1,'Concat_DTA, MGF, PKL, mzXML',1,'Y','XTandem',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (16,'Decon2LS','Decon2LS',1010,'\\gigasax\DMS_Parameter_Files\Decon2LS','G:\DMS_Parameter_Files\Decon2LS','??','HMMA_Peak','yes',0,'(na)',0,'N','Decon2LS','Old 32-bit DeconTools written in C++',0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (17,'TIC_D2L','TIC_D2L',1011,'\\gigasax\DMS_Parameter_Files\TIC_D2L','G:\DMS_Parameter_Files\TIC_D2L','??','TIC','yes',0,'(na)',0,'N','TIC_D2L',null,0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (18,'Decon2LS_Agilent','Decon2LS',1010,'\\gigasax\DMS_Parameter_Files\Decon2LS','G:\DMS_Parameter_Files\Decon2LS','??','HMMA_Peak','yes',0,'(na)',0,'N','Decon2LS','Old 32-bit DeconTools written in C++',0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (19,'TIC_D2L_Agilent','TIC_D2L',1011,'\\gigasax\DMS_Parameter_Files\TIC_D2L','G:\DMS_Parameter_Files\TIC_D2L','??','TIC','yes',0,'(na)',0,'N','TIC_D2L',null,0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (20,'Inspect','Inspect',1012,'\\gigasax\DMS_Parameter_Files\Inspect','G:\DMS_Parameter_Files\Inspect','IonTrapDefSettings.xml','IN_Peptide_Hit','no ',0,'Concat_DTA, MzXML',1,'Y','Inspect',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (21,'MSXML_Gen','MSXML_Gen',1013,'\\gigasax\DMS_Parameter_Files\MSXML_Gen','G:\DMS_Parameter_Files\MSXML_Gen','mzXML_Readw.xml','XML_Raw','no ',1,'(na)',0,'N','MSXML_Gen',null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (22,'DTA_Gen','DTA_Gen',1014,'\\gigasax\DMS_Parameter_Files\DTA_Gen','G:\DMS_Parameter_Files\DTA_Gen','DTAGen_ExtractMSn.xml','DTA_Peak','no ',1,'(na)',0,'N','DTA_Gen',null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (23,'MSClusterDAT_Gen','MSClusterDAT_Gen',1,'\\gigasax\DMS_Parameter_Files\MSClusterDAT_Gen','G:\DMS_Parameter_Files\MSClusterDAT_Gen','MSClusterDAT_ExtractMSn.xml','MSClusterDAT','no ',0,'(na)',0,'N','MSClusterDAT_Gen',null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (24,'DTA_Import','DTA_Import',1014,'\\gigasax\DMS_Parameter_Files\DTA_Import','G:\DMS_Parameter_Files\DTA_Import','SWTest_ExtDTA_Import.xml','DTA_Peak','no ',1,'(na)',0,'N','DTA_Import',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (25,'Sequest_UseExistingExternalDTA','Sequest',1000,'\\gigasax\DMS_Parameter_Files\Sequest','G:\DMS_Parameter_Files\Sequest','LCQDefSettings.txt','Peptide_Hit','no ',0,'Individual_DTA',1,'Y','Sequest',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (26,'XTandem_UseExistingExternalDTA','XTandem',1008,'\\gigasax\DMS_Parameter_Files\XTandem','G:\DMS_Parameter_Files\XTandem','??','XT_Peptide_Hit','no ',0,'Concat_DTA, MGF, PKL, mzXML',1,'Y','XTandem',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (27,'Decon2LS_V2','Decon2LS',1010,'\\gigasax\DMS_Parameter_Files\Decon2LS','G:\DMS_Parameter_Files\Decon2LS','??','HMMA_Peak','yes',1,'(na)',0,'N','DeconTools (Decon2LS_V2)','Extract deconvolved MS1 scan information',0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (28,'OMSSA','OMSSA',1016,'\\gigasax\DMS_Parameter_Files\OMSSA','G:\DMS_Parameter_Files\OMSSA','OMSSA_IonTrapDefSettings.xml','OM_Peptide_Hit','no ',0,'Concat_DTA',1,'Y','OMSSA',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (29,'Sequest_DTARefinery','Sequest_DTARefinery',1000,'\\gigasax\DMS_Parameter_Files\Sequest','G:\DMS_Parameter_Files\Sequest','FinniganDefSettings_DeconMSN_DTARef_NoMods.xml','Peptide_Hit','no ',0,'Individual_DTA',1,'Y','Sequest','Use DTA_Refinery to refine the parent ion masses, then search MS/MS spectra with Sequest.  Allows you to post-filter the search results with a tight ppm mass error tolerance.',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (30,'XTandem_HPC','XTandem',1008,'\\gigasax\DMS_Parameter_Files\XTandem','G:\DMS_Parameter_Files\XTandem','??','XT_Peptide_Hit','no ',0,'Concat_DTA, MGF, PKL, mzXML',1,'Y','XTandem',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (31,'XTandem_DTARefinery','XTandem_DTARefinery',1008,'\\gigasax\DMS_Parameter_Files\XTandem','G:\DMS_Parameter_Files\XTandem','??','XT_Peptide_Hit','no ',0,'Concat_DTA, MGF, PKL, mzXML',1,'Y','XTandem',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (32,'Inspect_UseExistingExternalDTA','Inspect',1012,'\\gigasax\DMS_Parameter_Files\Inspect','G:\DMS_Parameter_Files\Inspect','IonTrapDefSettings.xml','IN_Peptide_Hit','no ',0,'Concat_DTA, mzXML',1,'Y','Inspect',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (33,'LCMSFeature_Finder','LCMSFeature_Finder',1,'\\gigasax\DMS_Parameter_Files\LCMSFeatureFinder','G:\DMS_Parameter_Files\LCMSFeatureFinder','??','HMMA_Peak','yes',0,'(na)',0,'N','LCMSFeature_Finder',null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (34,'MSXML_Bruker','MSXML_Bruker',1,'\\gigasax\DMS_Parameter_Files\MSXML_Bruker','G:\DMS_Parameter_Files\MSXML_Bruker','mzXML_Bruker.xml','XML_Raw','no ',1,'(na)',0,'N','MSXML_Gen',null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (35,'MultiAlign','MultiAlign',1017,'\\gigasax\DMS_Parameter_Files\MultiAlign','G:\DMS_Parameter_Files\MultiAlign','??','MA_Peak_Matching','no ',0,'(na)',0,'N','MultiAlign',null,0,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (36,'MSGFPlus','MSGFPlus',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings.xml','MSG_Peptide_Hit','no ',1,'Concat_DTA',1,'Y','MSGFDB','Search MS/MS spectra with MS-GF+',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (37,'MSGFPlus_DTARefinery','MSGFPlus_DTARefinery',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings_DeconMSN_DTARef_NoMods.xml','MSG_Peptide_Hit','no ',1,'Concat_DTA',1,'Y','MSGFDB','Use DTA_Refinery to refine the parent ion masses, then search MS/MS spectra with MS-GF+. Allows you to post-filter the search results with a tight ppm mass error tolerance.',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (38,'MSAlign','MSAlign',1019,'\\gigasax\DMS_Parameter_Files\MSAlign','G:\DMS_Parameter_Files\MSAlign','??','MSA_Peptide_Hit','no ',1,'msalign',1,'N','MSAlign',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (39,'MSGFPlus_MzXML','MSGFPlus',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings_MzXML.xml','MSG_Peptide_Hit','no ',0,'mzXML',1,'Y','MSGFDB',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (40,'MSAlign_Bruker','MSAlign',1019,'\\gigasax\DMS_Parameter_Files\MSAlign','G:\DMS_Parameter_Files\MSAlign','??','MSA_Peptide_Hit','no ',0,'mzXML',1,'N','MSAlign',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (41,'SMAQC_MSMS','SMAQC',1020,'\\gigasax\DMS_Parameter_Files\SMAQC','G:\DMS_Parameter_Files\SMAQC','??','SQC','no ',1,'(na)',0,'N','SMAQC','Quality metrics analysis',1,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (42,'PRIDE_mzXML','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (43,'Phospho_FDR_Aggregator','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (44,'MultiAlign_Aggregator','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (45,'MAC_Spectral_Counting','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (46,'MAC_IMPROV','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (47,'MSDeconv_Bruker','MSDeconv',1019,'\\gigasax\DMS_Parameter_Files\MSAlign','G:\DMS_Parameter_Files\MSAlign','??','MSD_HMMA_Peak','no ',0,'mzXML',0,'N','MSDeconv',null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (48,'MSGFPlus_Bruker','MSGFPlus',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','MSGFDB_MzXML_Bruker.xml','MSG_Peptide_Hit','no ',0,'mzXML',1,'Y','MSGFDB',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (49,'MAC_Label_Free','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (50,'MAC_iTRAQ','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (51,'LipidMapSearch','LipidMapSearch',1021,'\\gigasax\DMS_Parameter_Files\LipidMapSearch','G:\DMS_Parameter_Files\LipidMapSearch','??','LMS','no ',0,'(na)',0,'N','LipidMapSearch',null,1,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (52,'MSGFPlus_IMS','MSGFPlus',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IMSDefSettings.xml','MSG_Peptide_Hit','no ',0,'DeconTools_ISOs',1,'Y','MSGFDB',null,1,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (53,'ProSightPC','ProSightPC',1,'(na)','(na)','ProSight_DataImport.xml','Data','no ',0,'Text',0,'N','ProSightPC',null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (54,'MAC_2D_LC','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (55,'PRIDE_Converter','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (56,'Isobaric_Labeling','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (57,'Global_Label-Free_AMT_Tag','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (58,'Isobaric_Labeling_No_IDM','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (59,'MSAlign_Histone','MSAlign_Histone',1022,'\\gigasax\DMS_Parameter_Files\MSAlign_Histone','G:\DMS_Parameter_Files\MSAlign_Histone','??','MSA_Peptide_Hit','no ',0,'mzXML',1,'N','MSAlign_Histone',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (60,'MSGFPlus_SplitFasta','MSGFPlus_SplitFasta',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','MSGFDB_DeconMSn_MergeResults_Top1.xml','MSG_Peptide_Hit','no ',1,'Concat_DTA',1,'Y','MSGFDB',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (61,'Decon2LS_V2_MzXML','Decon2LS',1010,'\\gigasax\DMS_Parameter_Files\Decon2LS','G:\DMS_Parameter_Files\Decon2LS','??','HMMA_Peak','yes',1,'(na)',0,'N','DeconTools (Decon2LS_V2)',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (62,'PeptideAtlas','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (63,'MSGFPlus_HPC','MSGFPlus',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','??','MSG_Peptide_Hit','no ',0,'Concat_DTA',1,'Y','MSGFDB',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (64,'MODa','MODa',1023,'\\gigasax\DMS_Parameter_Files\MODa','G:\DMS_Parameter_Files\MODa','IonTrapDefSettings_DeconMSN.xml','MODa_Peptide_Hit','no ',1,'Concat_DTA',1,'Y','MODa','Search MS/MS spectra with MODa',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (65,'MODa_DTARefinery','MODa_DTARefinery',1023,'\\gigasax\DMS_Parameter_Files\MODa','G:\DMS_Parameter_Files\MODa','IonTrapDefSettings_DeconMSN_DTARef_NoMods.xml','MODa_Peptide_Hit','no ',1,'Concat_DTA',1,'Y','MODa','Search MS/MS spectra with MODa',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (66,'GlyQ-IQ','GlyQ-IQ',1024,'\\gigasax\DMS_Parameter_Files\GlyQ-IQ','G:\DMS_Parameter_Files\GlyQ-IQ','GlyQIQ_HPC.xml','Gly_ID','no ',0,'(na)',0,'N','GlyQ-IQ',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (67,'MSPathFinder','MSPathFinder',1025,'\\gigasax\DMS_Parameter_Files\MSPathFinder','G:\DMS_Parameter_Files\MSPathFinder','MSPF_TopDown_Standard.xml','MSP_Peptide_Hit','no ',1,'(na)',1,'Y','MSPathFinder','Search MS/MS spectra with MSPathFinder',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (68,'MSGFPlus_MzML','MSGFPlus_MzML',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings_MzXML.xml','MSG_Peptide_Hit','no ',1,'mzML',1,'Y','MSGFDB','Use MZ_Refinery to refine the parent ion masses, then search MS/MS spectra with MS-GF+.  Creates .mzML files',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (69,'MSGFPlus_MzML_NoRefine','MSGFPlus_MzML',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings_MzML_NoRefine.xml','MSG_Peptide_Hit','no ',1,'mzML',1,'Y','MSGFDB','Use MZ_Refinery to characterize the parent ion distribute, but does not refine.  Creates .mzML files',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (70,'ProMex','ProMex',1026,'\\gigasax\DMS_Parameter_Files\ProMex','G:\DMS_Parameter_Files\ProMex','ProMex_TopDown_Standard.xml','PMX_MS1FT','no ',1,'(na)',0,'N','ProMex',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (71,'ProMex_Bruker','ProMex',1026,'\\gigasax\DMS_Parameter_Files\ProMex','G:\DMS_Parameter_Files\ProMex','ProMex_TopDown_Standard.xml','PMX_MS1FT','no ',1,'(na)',0,'N','ProMex',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (72,'NOMSI','NOMSI',1027,'\\gigasax\DMS_Parameter_Files\NOMSI','G:\DMS_Parameter_Files\NOMSI','NOMSI_Malak_Transformations.xml','NOM_Search','no ',1,'(na)',0,'N','',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (73,'MODPlus','MODPlus',1028,'\\gigasax\DMS_Parameter_Files\MODPlus','G:\DMS_Parameter_Files\MODPlus',null,'MODPlus_Peptide_Hit','no ',1,'mzML',1,'Y','MODPlus','Search MS/MS',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (74,'MODPlus_NoRefine','MODPlus',1028,'\\gigasax\DMS_Parameter_Files\MODPlus','G:\DMS_Parameter_Files\MODPlus',null,'MODPlus_Peptide_Hit','no ',0,'mzML',1,'Y','MODPlus','Search MS/MS',0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (75,'QC-ART','QC-ART',1029,'\\gigasax\DMS_Parameter_Files\QC-ART','G:\DMS_Parameter_Files\QC-ART','??','QCA','no ',1,'(na)',0,'N',null,'QC of iTRAQ datasets using SMAQC results',1,0,1)
INSERT INTO [T_Analysis_Tool] VALUES (76,'PBF_Gen','PBF_Gen',1,'(na)','(na)','(na)',null,'no ',1,'(na)',0,'N',null,null,0,1,0)
INSERT INTO [T_Analysis_Tool] VALUES (77,'NOMSI_MzXML','NOMSI',1027,'\\gigasax\DMS_Parameter_Files\NOMSI','G:\DMS_Parameter_Files\NOMSI','NOMSI_Malak_Transformations.xml','NOM_Search','no ',1,'(na)',0,'N',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (78,'MSGFPlus_DTARefinery_SplitFasta','MSGFPlus_DTARefinery',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','MSGFDB_DeconMSn_Centroid_Top500_DTARef_NoMods_15Parts_MergeResults_Top1.xml','MSG_Peptide_Hit','no ',1,null,1,'Y','',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (79,'MSGFPlus_MzML_SplitFasta','MSGFPlus_MzML',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings_MzML_StatCysAlk_6plexTMT_phospho_5Parts_MergeResults_Top1.xml','MSG_Peptide_Hit','no ',1,null,1,'Y',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (80,'MAC_TMT10Plex','Broker_Job',1,'(na)','(na)','(na)',null,'no ',0,'(na)',0,'N','(none)',null,0,0,0)
INSERT INTO [T_Analysis_Tool] VALUES (81,'Formularity_Bruker','Formularity',1030,'\\gigasax\DMS_Parameter_Files\Formularity','G:\DMS_Parameter_Files\Formularity','Formularity_DefSettings.xml','FRM_Search','no ',0,'(na)',0,'N',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (82,'TopFD','TopFD',1031,'\\gigasax\DMS_Parameter_Files\TopFD','G:\DMS_Parameter_Files\TopFD','??','MSD_HMMA_Peak','no ',0,'mzML',0,'N','n/a',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (83,'TopPIC','TopPIC',1032,'\\gigasax\DMS_Parameter_Files\TopPIC','G:\DMS_Parameter_Files\TopPIC','??','TPC_Peptide_Hit','no ',1,'msalign',1,'N','n/a',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (84,'ThermoPeakDataExporter','ThermoPeakDataExporter',1,'(na)','(na)','ThermoPeakDataExporter_DefSettings.xml','TSV_Peak','no ',0,'(na)',0,'N','n/a',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (85,'Formularity_Thermo','Formularity',1030,'\\gigasax\DMS_Parameter_Files\Formularity','G:\DMS_Parameter_Files\Formularity','Formularity_DefSettings.xml','FRM_Search','no ',1,'(na)',0,'N',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (86,'MSGFPlus_DeconMSn_MzRefinery','MSGFPlus_MzML',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings_DeconMSN_MzRefinery_StatCysAlk_6plexTMT.xml','MSG_Peptide_Hit','no ',1,'mzML',1,'Y',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (87,'Formularity_Bruker_Decon','Formularity',1030,'\\gigasax\DMS_Parameter_Files\Formularity','G:\DMS_Parameter_Files\Formularity','Formularity_DefSettings.xml','FRM_Search','no ',1,null,0,'N',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (88,'MSFragger','MSFragger',1033,'\\gigasax\DMS_Parameter_Files\MSFragger','G:\DMS_Parameter_Files\MSFragger','??','MSF_Peptide_Hit','no ',0,'mzML',1,'N','n/a',null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (89,'PepProtProphet','PepProtProphet',1,'(na)','(na)','??','TSV','no ',0,'(na)',1,'N',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (90,'MSGFPlus_MzML_SplitFasta_NoRefine','MSGFPlus_MzML',1018,'\\gigasax\DMS_Parameter_Files\MSGFPlus','G:\DMS_Parameter_Files\MSGFPlus','IonTrapDefSettings_MzML_5Parts_MergeResults_Top1.xml','MSG_Peptide_Hit','no ',1,null,1,'Y',null,null,0,1,1)
INSERT INTO [T_Analysis_Tool] VALUES (91,'MaxQuant','MaxQuant',1034,'\\gigasax\DMS_Parameter_Files\MaxQuant','G:\DMS_Parameter_Files\MaxQuant','??','MXQ_Peptide_Hit','no ',1,null,1,'N',null,null,0,1,1)
