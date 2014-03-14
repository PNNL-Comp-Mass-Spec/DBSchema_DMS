/****** Object:  Table [T_Step_Tools] ******/
/****** RowCount: 56 ******/
SET IDENTITY_INSERT [T_Step_Tools] ON
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (42,'APE','Data Filtering and Aggregation','Runs workflows to filter and aggregate data',0,0,1,250,'','Y','','','APE')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (47,'AScore','Standard Processing for DMS tool','Calculates phosphoproteomics FDR for datasets and aggregates the results',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\AScore','','AScore')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (21,'Bogus','Peptide Search','Testing software, again',0,0,1,250,'<section name="Search" tool="Sequest" category="basic"><item key="AJ_ParmFile" value=""><field label="Parameter File" type="text" size="60" rules="trim|required|max_length[255]" maxlength="255"><chooser type="list-report.helper" Target="helper_aj_param_file/report" XRef="AJ_ToolName" Delimiter="," /></field></item><item key="OrganismName" value=""><field label="Organism" type="text" size="30" rules="trim|required|max_length[50]" maxlength="80"><chooser type="list-report.helper" Target="helper_organism/report" Delimiter="," /></field></item><item key="legacyFastaFileName" value=""><field label="Organism DB File" type="text" size="60" rules="trim|required|max_length[64]" maxlength="80" /></item><item key="ProteinCollectionList" value="na"><field label="Protein Collection List" type="area" rules="trim|max_length[4000]" rows="3" cols="60"><chooser type="list-report.helper" Target="helper_protein_collection/report" XRef="AJ_Organism" Delimiter="," /></field></item><item key="ProteinOptions" value="seq_direction=forward"><field label="Protein Options List" type="area" rules="trim|max_length[256]" rows="2" cols="60"><chooser type="picker.replace" PickListName="protOptSeqDirPickList" Delimiter="," /></field></item></section>','Y','','','Bogus')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (43,'Cyclops','Statistical Analysis','Performs various statistical analysis',0,0,1,250,'','Y','','','Cyclops')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (14,'DataExtractor','Peptide Extraction','Creates loadable peptide ID file and first hits file',0,0,2,250,'<section name="PeptideHitResultsProcessorOptions" tool="DataExtractor" category="basic"><item key="EnzymeMatchSpecLeftResidue" value="[KR]" /><item key="EnzymeMatchSpecRightResidue" value="[^P]" /></section>','Y','','CPU_Load set to 2 to prevent more than 3 copies of the Data Extractor running on one machine (Peptide Prophet tends to run out of memory)','DataExtractor')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (51,'DataImport','Data Import','Copies data files from an external source into an analysis job folder',0,0,1,64,'','Y','','','DataImport')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (7,'Decon2LS','Deisotoping','Uses Decon2LS to deisotope spectra',0,0,1,250,'','N','\\gigasax\DMS_Parameter_Files\Decon2LS','','Decon2LS')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (8,'Decon2LS_Agilent','Deisotoping','',0,0,1,250,'','N','','','Decon2LS_Agilent')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (27,'Decon2LS_V2','Deisotoping','Uses Decon2LS AutoProcessor to deisotope spectra (supports IMS data and RAPID)',0,0,1,250,'','N','\\gigasax\DMS_Parameter_Files\Decon2LS','','Decon2LS_V2')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (15,'DTA_Gen','DTA Generator','Creates DTA files according to values in settings file',1,0,1,250,'<section name="DtaGenerator" tool="DTA_Gen" category="basic"><item key="DtaGenerator" value="extract_msn.exe" /></section><section name="Charges" tool="DTA_Gen" category="advanced"><item key="CreateDefaultCharges" value="True" /><item key="ExplicitChargeStart" value="0" /><item key="ExplicitChargeEnd" value="0" /></section><section name="ScanControl" tool="DTA_Gen" category="advanced"><item key="ScanStart" value="1" /><item key="ScanStop" value="999999" /><item key="MaxIntermediateScansWhenGrouping" value="1" /></section><section name="MWControl" tool="DTA_Gen" category="advanced"><item key="MWStart" value="200" /><item key="MWStop" value="5000" /></section><section name="IonCounts" tool="DTA_Gen" category="advanced"><item key="IonCount" value="35" /></section><section name="MassTol" tool="DTA_Gen" category="advanced"><item key="MassTol" value="3" /></section>','Y','\\gigasax\DMS_Parameter_Files\DTA_Gen','','DTA_Gen')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (25,'DTA_Import','DTA Importer','Imports manually generated DTA files',0,0,1,250,'','Y','','','DTA_Import')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (30,'DTA_Refinery','DTA Generator','Reads DTA files (typically created by DeconMSn), then refines the parent mass for each spectrum using and X!Tandem search',1,0,4,250,'<section name="DtaGenerator" tool="DTA_Gen"><item key="DtaGenerator" value="DeconMSN.exe" /></section><section name="DTARefinery"><item key="DTARefineryXMLFile" value="DTARef_Lowess_NoMods.xml" /></section>','Y','\\gigasax\DMS_Parameter_Files\DTARefinery','','DTA_Refinery')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (22,'DTA_Split','DTA Generator','Splits DTA files created by DTAGen',0,1,1,250,'<section name="ParallelInspect"><item key="SubDTAFileBaseName" Value="_Part@_dta.txt" /><item key="SubResultFileBaseName" Value="_Part@_inspect.txt" /></section>','Y','','','DTA_Split')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (9,'ICR2LS','Deisotoping','Uses ICR-2LS to deisotope spectra for Bruker datasets',0,0,1,250,'','N','\\gigasax\DMS_Parameter_Files\ICR2LS','','ICR2LS')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (46,'IDM','ITRAQ Interference Detection','Tool for calculating interference within isolation window',0,0,1,250,'','Y','','','IDM')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (50,'IDP_Mac','Protein Grouping','Runs IDPicker for the MAC pipline (as of September 2013, this tool is not used by any scripts)',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\IDP_MAC','','IDP_MAC')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (45,'IDPicker','Protein Grouping','Runs IDPicker',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\IDPicker','','IDPicker')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (17,'Inspect','Peptide Search','Identify peptides by searching protein collection',0,0,1,250,'','N','\\gigasax\DMS_Parameter_Files\Inspect','','Inspect')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (18,'InspectDataExtractor','Peptide Extraction','Creates loadable peptide ID file and first hits file',0,0,1,250,'','Y','','','InspectDataExtractor')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (23,'InspectResultsAssembly','Peptide Extraction','Combines peptide search result files generated by running Inspect in parallel',0,1,1,250,'<section name="ParallelInspect"><item key="SubDTAFileBaseName" Value="_Part@_dta.txt" /><item key="SubResultFileBaseName" Value="_Part@_inspect.txt" /></section>','Y','','','InspectResultsAssembly')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (29,'LCMSFeatureFinder','Feature Detection','Groups deisotoped data from Decon2LS to form LC-MS Features',0,1,1,250,'<section name="LCMSFeatureFinder"><item key="LCMSFeatureFinderIniFile" value="FF_IMS_50ppm_2500Intensity_2009-12-21.ini" /></section>','N','\\gigasax\DMS_Parameter_Files\LCMSFeatureFinder','','LCMSFeatureFinder')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (48,'LipidMapSearch','Lipid Search','Searches a single dataset or a pair of datasets (positive mode and negative mode) against the Lipid Maps database',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\LipidMapSearch','','LipidMapSearch')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (26,'LTQ_FTPek','Deisotoping','Uses ICR-2LS to deisotope spectra for Finnigan datasets',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\LTQ_FTPek','','LTQ_FTPek')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (41,'Mage','Data Extraction','Performs various types of data extraction',0,0,1,250,'','Y','','','Mage')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (13,'MASIC_Agilent','MASIC','',0,0,1,250,'','N','\\gigasax\DMS_Parameter_Files\MASIC','','MASIC_Agilent')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (12,'MASIC_Finnigan','MASIC','',0,0,1,250,'','N','\\gigasax\DMS_Parameter_Files\MASIC','','MASIC_Finnigan')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (40,'MSAlign','Peptide Search','Searches MSAlign result files for peptides',0,0,7,16000,'','N','\\gigasax\DMS_Parameter_Files\MSAlign','','MSAlign')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (55,'MSAlign_Histone','Peptide Search','Searches MSAlign result files for histone peptides',0,0,7,16000,'','N','\\gigasax\DMS_Parameter_Files\MSAlign_Histone','','MSAlign_Histone')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (49,'MSAlign_Quant','Peptide Extraction','Quantifies MSAlign results',0,0,1,1024,'','N','\\gigasax\DMS_Parameter_Files\DeconToolsWorkflows','','MSAlign_Quant')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (24,'MSClusterDTAtoDAT','MSMS Spectrum Filter','Produce an MSCluster-compatible DAT file from an existing DTA',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\MSClusterDAT_Gen','','MSClusterDTAtoDAT')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (39,'MSDeconv','Deisotoping','Deisotopes peptides with charge 4+ or higher; intended for top-down or middle-down datasets',0,0,1,2048,'','Y','','','MSDeconv')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (34,'MSGF','Peptide Extraction','Runs MSGF, aka the MS-GeneratingFunction (CPU Load is 4 to keep to just one or two tasks per box)',0,0,2,2048,'','Y','','','MSGF')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (38,'MSGFPlus','Peptide Search','Runs MSGF+ (CPU load is 4 to allow for debugging, but MSGF+ will use 1 fewer than the number of cores)',0,0,4,4096,'','N','\\gigasax\DMS_Parameter_Files\MSGFDB','','MSGFDB')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (58,'MSGFPlus_HPC','Peptide Search','Runs MSGF+ on the Deception HPC Compute Cluster (server admin: Clay Hagler)',0,0,1,250,'','N','\\gigasax\DMS_Parameter_Files\MSGFDB','','MSGFDB_HPC')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (52,'MSGFPlus_IMS','Peptide Search','Processes IMS MSn data with MSGFDB_IMS; requires a DeconTools job as import',0,0,4,4096,'','N','\\gigasax\DMS_Parameter_Files\MSGFDB','','MSGFDB_IMS')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (4,'MSMSSpectraPreprocessor','MSMS Spectrum Filter','Produce modified DTA by filtering existing DTA',0,1,1,250,'<section name="SpectraFilter" tool="MSMSSpectraPreprocessor" category="basic"><item key="FilterType" value="" /></section><section name="FilterOptions" tool="MSMSSpectraPreprocessor" category="advanced"><item key="FilterMode" value="3" /><item key="MinimumQualityScore" value="0.25" /><item key="GenerateFilterReport" value="True" /><item key="IncludeBPIAndNLStatsOnFilterReport" value="True" /><item key="OverwriteExistingFiles" value="True" /><item key="DiscardValidSpectra" value="False" /><item key="EvaluateSpectrumQualityOnly" value="False" /><item key="MSLevelFilter" value="0" /></section><section name="FilterMode3" tool="MSMSSpectraPreprocessor" category="advanced"><item key="BasePeakIntensityMinimum" value="1000" /><item key="MassToleranceHalfWidthMZ" value="0.7" /><item key="NLAbundanceThresholdFractionMax" value="0.5" /><item key="LimitToChargeSpecificIons" value="True" /><item key="ConsiderWaterLoss" value="True" /><item key="SpecificMZLosses" value="" /></section>','Y','','','MSMSSpectraPreprocessor')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (35,'MSXML_Bruker','XML File Generator','Creates mzXML or mzML files from Bruker .D folders',1,0,1,250,'<section name="MSXMLGenerator"><item key="MSXMLGenerator" value="CompassXport.exe" /><item key="MSXMLOutputType" value="mzXML" /><item key="CentroidMSXML" value="True" /></section>','Y','\\gigasax\DMS_Parameter_Files\MSXML_Bruker','','MSXML_Bruker')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (22,'MSXML_Gen','XML File Generator','Creates mzXML or mzML files from .Raw files',1,0,1,250,'<section name="MSXMLGenerator"><item key="MSXMLGenerator" value="ReadW.exe" /><item key="MSXMLOutputType" value="mzXML" /><item key="CentroidMSXML" value="False" /></section>','Y','\\gigasax\DMS_Parameter_Files\MSXML_Gen','','MSXML_Gen')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (36,'MultiAlign','Peak matching','Matches LCMSFeatureFinder results across datasets and/or to an AMT tag database',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\MultiAlign','','MultiAlign')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (37,'MultiAlign_Aggregator','Peak Matching','Matches LCMSFeatureFinder results across datasets and/or to an AMT tag database',0,0,1,250,'','Y','','','MultiAlign_Aggregator')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (32,'mzXML_Aggregator','mzXML Aggregator','Extracts mzXML results from multiple mzXML jobs and aggregates the result',0,0,1,250,'','Y','','','mzXML_Aggregator')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (19,'mzXMLSpecraPreprocessor','mzXML MSMS Spectrum Filter','',0,0,1,250,'','Y','','','mzXMLSpecraPreprocessor')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (28,'OMSSA','Peptide Search','Runs OMSSA',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\OMSSA','','OMSSA')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (33,'Phospho_FDR_Aggregator','PhosphoFDRAggregator','Calculates phosphoproteomics FDR for datasets and aggregates the results',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\AScore','','Phospho_FDR_Aggregator')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (54,'PRIDE_Converter','PSM Result Aggregator','Converts Peptide_Hit results (Sequest, X!Tandem, or MSGFDB) to the msgf-pride.xml format',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\PRIDE_Converter','','PRIDE_Converter')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (53,'ProSight_Quant','Peptide Quantitation','Quantifies ProSightPC results',0,0,1,1024,'','N','\\gigasax\DMS_Parameter_Files\DeconToolsWorkflows','','ProSight_Quant')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (57,'RepoPkgr','PSM Result Aggregator','Aggregates data and results files from DMS into package that can be uploaded to a public proteomics repository',0,0,1,250,'','Y','','','')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (56,'Results_Cleanup','Utility','Looks for Results.db3 files in MAC jobs; deletes all except the one in the final job step',0,0,1,250,'','Y','','','Results_Cleanup')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (16,'Results_Transfer','Results Folder Move','Moves results folder from Xfer to storage',0,0,1,250,'','Y','','','Results_Transfer')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (5,'Sequest','Peptide Search','Identify peptides by searching protein collection',0,0,1,100,'<section name="Search" tool="Sequest" category="basic"><item key="AJ_ParmFile" value="" /><item key="OrganismName" value="" /><item key="legacyFastaFileName" value="" /><item key="ProteinCollectionList" value="na" /><item key="ProteinOptions" value="seq_direction=forward" /></section>','N','\\gigasax\DMS_Parameter_Files\Sequest','','Sequest')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (44,'SMAQC','SMAQC','Runs SMAQC',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\SMAQC','','SMAQC')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (10,'TIC_D2L','TIC','',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\TIC_D2L','','TIC_D2L')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (11,'TIC_D2L_Agilent','TIC','',0,0,1,250,'','Y','\\gigasax\DMS_Parameter_Files\TIC_D2L','','TIC_D2L_Agilent')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (6,'XTandem','Peptide Search','Identify peptides by searching protein collection',0,0,7,250,'<section name="Search" tool="Sequest" category="basic"><item key="ParmFileName" value="" /><item key="OrganismName" value="" /><item key="legacyFastaFileName" value="" /><item key="ProteinCollectionList" value="na" /><item key="ProteinOptions" value="seq_direction=forward" /></section>','N','\\gigasax\DMS_Parameter_Files\XTandem','','XTandem')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (31,'XTandem_HPC','Peptide Search','Runs XTandem on Chinook high-performance computer',0,0,0,250,'','Y','\\gigasax\DMS_Parameter_Files\XTandem','','XTandem_HPC')
INSERT INTO [T_Step_Tools] (ID, Name, Type, Description, Shared_Result_Version, Filter_Version, CPU_Load, Memory_Usage_MB, Parameter_Template, Available_For_General_Processing, Param_File_Storage_Path, Comment, Tag) VALUES (20,'XTandemDataExtractor','Peptide Extraction','Creates loadable peptide ID file and first hits file',0,0,1,250,'','Y','','','XTandemDataExtractor')
SET IDENTITY_INSERT [T_Step_Tools] OFF
