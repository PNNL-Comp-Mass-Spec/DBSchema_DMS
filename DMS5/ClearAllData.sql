/****** Object:  StoredProcedure [dbo].[ClearAllData] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE ClearAllData
/****************************************************
** 
**	Desc: 
**		This is a DANGEROUS procedure that will clear all
**		data from all of the tables in this database
**
**		This is useful for creating test databases
**		or for migrating the DMS databases to a new laboratory
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	08/21/2015 mem - Initial release
**			09/16/2015 mem - Added exclusions for entries related to in-silico instrument 'DMS_Pipeline_Data'
**			10/29/2015 mem - Disabling functionality via a goto (for safety)
**    
*****************************************************/
(
	@ServerNameFailsafe varchar(64) = 'Pass in the name of the current server to confirm that you truly want to delete data',
	@CurrentDateFailsafe varchar(64) = 'Enter the current date, in the format yyyy-mm-dd',
	@infoOnly tinyint = 1,
	@message varchar(255) = '' output
)
As
	Set NoCount On
	
	declare @myRowCount int
	declare @myError int
	set @myRowCount = 0
	set @myError = 0

	set @infoOnly = IsNull(@infoOnly, 1)
	set @message = ''


	-- Functionality disabled for safety
	--
	Set @message = 'This procedure is disabled; edit the code to re-enable'
	Select @message
	Goto Done


	-------------------------------------------------
	-- Verify that we truly should do this
	-------------------------------------------------
	
	If @ServerNameFailsafe <> @@ServerName
	Begin
		set @message = 'You must enter the name of the server hosting this database'		
		Goto Done
	End
	
	Declare @userDate date 
	set @userDate = Convert(date, @CurrentDateFailsafe)
	
	If IsNull(@userDate, '') = '' OR @userDate <> Cast(GetDate() as Date)
	Begin
		set @message = 'You must set @CurrentDateFailsafe to the current date, in the form yyyy-mm-dd'		
		Goto Done
	End

	-------------------------------------------------
	-- Remove foreign keys
	-------------------------------------------------

	If @infoOnly = 0
	Begin
		DISABLE TRIGGER trig_ud_T_Analysis_Job on T_Analysis_Job;
		DISABLE TRIGGER trig_ud_T_Dataset on T_Dataset;
		DISABLE TRIGGER trig_ud_T_Experiments on T_Experiments;

		If Exists (SELECT * FROM sys.indexes WHERE name = 'IX_T_Analysis_Job_AJ_ToolNameCached')
		Begin
			DROP INDEX IX_T_Analysis_Job_AJ_ToolNameCached ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_ToolID_include_ParmFile ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_AJ_Last_Affected ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_AJ_StateNameCached ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_RequestID ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_AJ_datasetID ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_OrganismDBName ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_ToolID_include_DatasetID ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_AJ_finish ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_AJ_created ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_ToolID_JobID_StateName_DatasetID ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_ToolID_JobID_OrganismID_DatasetID ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_ToolID_JobID_DatasetID_include_AJStart ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_StateID_include_JobPriorityToolDataset ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_DatasetID_JobID_StateID ON dbo.T_Analysis_Job
			DROP INDEX IX_T_Analysis_Job_AJ_StateID_AJ_JobID ON dbo.T_Analysis_Job
		End
		
		If Exists (SELECT * FROM sys.indexes WHERE name = 'IX_T_Dataset_DateSortKey')
		Begin
			DROP INDEX IX_T_Dataset_DateSortKey ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Sec_Sep ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_InstrumentNameID_AcqTimeStart_include_DatasetID_DSRating ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Rating_include_InstrumentID_DatasetID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_InstrumentNameID_LastAffected_include_State ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_DatasetID_InstrumentNameID_StoragePathID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_InstrumentNameID_TypeID_include_DatasetID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_StoragePathID_Created_InstrumentNameID_Rating_DatasetID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_DatasetID_include_DatasetNum_InstrumentNameID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_DatasetID_Created_StoragePathID_Include_DatasetNum ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_LC_column_ID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_InstNameID_Dataset_DatasetID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_ID_Created_ExpID_SPathID_InstrumentNameID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_StoragePathID_Created_ExpID_InstrumentNameID_DatasetID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Dataset_ID_DS_Created ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Dataset_ID_Exp_ID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Exp_ID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_State_ID ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Acq_Time_Start ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Dataset_Num ON dbo.T_Dataset
			DROP INDEX IX_T_Dataset_Created ON dbo.T_Dataset
		End
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Analysis_Job_T_Analysis_Job_Batches')
			ALTER TABLE dbo.T_Analysis_Job
				DROP CONSTRAINT FK_T_Analysis_Job_T_Analysis_Job_Batches

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Analysis_Job_T_Analysis_Job_Request')
			ALTER TABLE dbo.T_Analysis_Job
				DROP CONSTRAINT FK_T_Analysis_Job_T_Analysis_Job_Request

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Analysis_Job_T_Dataset')
			ALTER TABLE dbo.T_Analysis_Job
				DROP CONSTRAINT FK_T_Analysis_Job_T_Dataset

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job')
			ALTER TABLE dbo.T_Analysis_Job_Processor_Group_Associations
				DROP CONSTRAINT FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job


		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Dataset_T_Experiments')
			ALTER TABLE dbo.T_Dataset
				DROP CONSTRAINT FK_T_Dataset_T_Experiments

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Dataset_Storage_Move_Log_T_Dataset')
			ALTER TABLE dbo.T_Dataset_Storage_Move_Log
				DROP CONSTRAINT FK_T_Dataset_Storage_Move_Log_T_Dataset

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Dataset_Archive_T_Dataset')
			ALTER TABLE dbo.T_Dataset_Archive
				DROP CONSTRAINT FK_T_Dataset_Archive_T_Dataset

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Requested_Run_T_Dataset')
			ALTER TABLE dbo.T_Requested_Run
				DROP CONSTRAINT FK_T_Requested_Run_T_Dataset

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Dataset_Info_T_Dataset')
			ALTER TABLE dbo.T_Dataset_Info
				DROP CONSTRAINT FK_T_Dataset_Info_T_Dataset

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Experiment_Cell_Cultures_T_Experiments')
			ALTER TABLE dbo.T_Experiment_Cell_Cultures
				DROP CONSTRAINT FK_T_Experiment_Cell_Cultures_T_Experiments

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Experiment_Groups_T_Experiments')
			ALTER TABLE dbo.T_Experiment_Groups
				DROP CONSTRAINT FK_T_Experiment_Groups_T_Experiments

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Experiment_Group_Members_T_Experiments')
			ALTER TABLE dbo.T_Experiment_Group_Members
				DROP CONSTRAINT FK_T_Experiment_Group_Members_T_Experiments
	
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Instrument_Name_T_storage_path_SourcePathID')
			ALTER TABLE dbo.T_Instrument_Name
				DROP CONSTRAINT FK_T_Instrument_Name_T_storage_path_SourcePathID

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Instrument_Name_T_storage_path_StoragePathID')
			ALTER TABLE dbo.T_Instrument_Name
				DROP CONSTRAINT FK_T_Instrument_Name_T_storage_path_StoragePathID

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Param_File_Mass_Mods_T_Param_Files')
			ALTER TABLE dbo.T_Param_File_Mass_Mods
				DROP CONSTRAINT FK_T_Param_File_Mass_Mods_T_Param_Files

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Param_Entries_T_Param_Files')
			ALTER TABLE dbo.T_Param_Entries
				DROP CONSTRAINT FK_T_Param_Entries_T_Param_Files

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Research_Team_Membership_T_Research_Team')
			ALTER TABLE dbo.T_Research_Team_Membership
				DROP CONSTRAINT FK_T_Research_Team_Membership_T_Research_Team

	End
	
	-------------------------------------------------
	-- Truncate tables
	-------------------------------------------------

	If @infoOnly = 0
	Begin
		Select 'Deleting data' AS Task

		DELETE FROM T_Analysis_Job
		WHERE NOT AJ_JobID IN ( SELECT T_Analysis_Job.AJ_jobID
		                        FROM T_Instrument_Name
		                             INNER JOIN T_Dataset
		                               ON T_Instrument_Name.Instrument_ID = T_Dataset.DS_instrument_name_ID
		                             INNER JOIN T_Analysis_Job
		                               ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
		                        WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1') )


		DELETE FROM T_Analysis_Job_Batches
		WHERE NOT Batch_ID IN (Select AJ_BatchID FROM T_Analysis_Job)
		
		DELETE FROM T_Analysis_Job_ID
		WHERE NOT ID IN (Select AJ_JobID FROM T_Analysis_Job)

		DELETE FROM T_Analysis_Job_Processor_Group_Associations
		WHERE NOT Job_ID IN (Select AJ_JobID FROM T_Analysis_Job) 

		DELETE T_Analysis_Job_Processor_Group_Membership
		FROM T_Analysis_Job_Processor_Group_Membership AJPGM
		     INNER JOIN T_Analysis_Job_Processors AJP
		       ON AJPGM.Processor_ID = AJP.ID
		WHERE NOT (AJPGM.Group_ID = 100 AND
		           AJP.Processor_Name LIKE 'Pub-10-%') AND
		      NOT (AJPGM.Group_ID = 151 AND
		           AJP.Processor_Name LIKE 'Pub-80-%')

		DELETE FROM T_Predefined_Analysis_Scheduling_Rules
		WHERE (NOT (SR_processorGroupID IN (100, 115, 151)))

		DELETE FROM T_Analysis_Job_Processor_Group
		WHERE ID NOT IN (100, 115, 151)
	   
	    DELETE FROM T_Analysis_Job_Processors
	    WHERE NOT Processor_Name LIKE 'Pub-10-%' AND
	          NOT Processor_Name LIKE 'Pub-80-%'
	    
	    DELETE FROM T_Analysis_Job_Request
	    WHERE AJR_RequestID > 1 AND
	          AJR_RequestID NOT IN
	          ( SELECT DISTINCT T_Analysis_Job_Request.AJR_requestID
	            FROM T_Instrument_Name
	                INNER JOIN T_Dataset
	                ON T_Instrument_Name.Instrument_ID 
	                    = T_Dataset.DS_instrument_name_ID
	                INNER JOIN T_Analysis_Job
	                ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
	                INNER JOIN T_Analysis_Job_Request
	                ON T_Analysis_Job.AJ_requestID 
	                    = T_Analysis_Job_Request.AJR_requestID
	            WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1') )
	
		DELETE FROM T_Dataset_Archive
		WHERE NOT AS_Dataset_ID IN 
			  ( SELECT T_Dataset.Dataset_ID
		        FROM T_Dataset
		            INNER JOIN T_Instrument_Name
		            ON T_Dataset.DS_instrument_name_ID 
		                = T_Instrument_Name.Instrument_ID
		        WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1') )
				
	    DELETE FROM T_Archive_Path
	    WHERE AP_instrument_name_ID > 0 AND
	          NOT AP_Path_ID IN 
			  ( SELECT T_Archive_Path.AP_path_ID
	            FROM T_Archive_Path
	                INNER JOIN T_Dataset_Archive
	                    ON T_Archive_Path.AP_path_ID = T_Dataset_Archive.AS_storage_path_ID
	                INNER JOIN T_Dataset
	                    ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
	                INNER JOIN T_Instrument_Name
	                    ON T_Dataset.DS_instrument_name_ID 
	                    = T_Instrument_Name.Instrument_ID
	            WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1') )

		DELETE FROM T_Requested_Run
		WHERE (ID NOT IN
			   (SELECT T_Requested_Run.ID
			 FROM T_Instrument_Name INNER JOIN
				T_Dataset ON T_Instrument_Name.Instrument_ID = T_Dataset.DS_instrument_name_ID INNER JOIN
				T_Requested_Run ON T_Dataset.Dataset_ID = T_Requested_Run.DatasetID
			 WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1')))

		DELETE FROM T_Requested_Run_Batches
	    WHERE ID > 0
	
		DELETE FROM T_Dataset
		WHERE NOT (Dataset_ID IN
			   (SELECT T_Dataset.Dataset_ID
			 FROM T_Instrument_Name INNER JOIN
				T_Dataset ON T_Instrument_Name.Instrument_ID = T_Dataset.DS_instrument_name_ID
			 WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1')))

		DELETE FROM T_Experiment_Cell_Cultures
		WHERE NOT CC_ID IN ( SELECT T_Experiment_Cell_Cultures.CC_ID
                     FROM T_Experiment_Cell_Cultures
                          INNER JOIN T_Experiments
                            ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID
                     WHERE (T_Experiments.Experiment_Num = 'Placeholder') OR
                           (T_Experiment_Cell_Cultures.Exp_ID IN 
                            ( SELECT T_Experiments.Exp_ID
                              FROM T_Instrument_Name
                                   INNER JOIN T_Dataset
                                     ON T_Instrument_Name.Instrument_ID 
                                        = T_Dataset.DS_instrument_name_ID
                                   INNER JOIN T_Experiments
                                     ON T_Dataset.Exp_ID = T_Experiments.Exp_ID
                              WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1') )) OR
                           (T_Experiment_Cell_Cultures.Exp_ID IN 
                            ( SELECT DISTINCT T_Requested_Run.Exp_ID
                              FROM T_Experiments
                                   INNER JOIN T_Requested_Run
                                     ON T_Experiments.Exp_ID = T_Requested_Run.Exp_ID )) )

		DELETE FROM T_Experiments
		WHERE (Experiment_Num <> 'Placeholder') AND
		      (Exp_ID NOT IN ( SELECT T_Experiments.Exp_ID
		                       FROM T_Instrument_Name
		                            INNER JOIN T_Dataset
		                              ON T_Instrument_Name.Instrument_ID = T_Dataset.DS_instrument_name_ID
		                            INNER JOIN T_Experiments
		                              ON T_Dataset.Exp_ID = T_Experiments.Exp_ID
		                       WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1') )) AND
		      (Exp_ID NOT IN ( SELECT DISTINCT T_Requested_Run.Exp_ID
		                      FROM T_Experiments
		                           INNER JOIN T_Requested_Run
		                             ON T_Experiments.Exp_ID = T_Requested_Run.Exp_ID ))

		DELETE T_Experiment_Cell_Cultures
		FROM T_Experiment_Cell_Cultures LEFT OUTER JOIN
		T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID
		WHERE (T_Experiments.Exp_ID IS NULL)

		DELETE T_Experiment_Group_Members
		FROM T_Experiment_Group_Members LEFT OUTER JOIN
		T_Experiments ON T_Experiment_Group_Members.Exp_ID = T_Experiments.Exp_ID
		WHERE (T_Experiments.Exp_ID IS NULL)

		DELETE T_Experiment_Groups
		FROM T_Experiment_Groups LEFT OUTER JOIN
		T_Experiment_Group_Members ON 
		T_Experiment_Groups.Group_ID = T_Experiment_Group_Members.Group_ID
		WHERE (T_Experiment_Group_Members.Exp_ID IS NULL)
		                         
		DELETE FROM T_Sample_Prep_Request_Items 
		WHERE ID > 0
		                            
		DELETE FROM T_Sample_Prep_Request
	    WHERE ID > 0

		TRUNCATE TABLE T_Cached_Instrument_Usage_by_Proposal

	    DELETE FROM T_EUS_Proposal_Users
	    WHERE Proposal_ID <> 1000

	    DELETE FROM T_EUS_Proposals
	    WHERE Proposal_ID <> 1000
            
	    DELETE FROM T_Cell_Culture
	    WHERE CC_Name <> '(none)' AND
	          NOT CC_ID IN ( SELECT ECC.CC_ID
	                         FROM T_Experiment_Cell_Cultures ECC
	                   INNER JOIN T_Cell_Culture C
	    ON ECC.CC_ID = C.CC_ID )

		DELETE FROM T_Storage_Path
		WHERE (SP_path <> '(none)') AND 
		      (SP_instrument_name <> 'DMS_Pipeline_Data') AND
		      (NOT (SP_path_ID IN
			   (SELECT T_Storage_Path.SP_path_ID
			    FROM T_Storage_Path INNER JOIN
				     T_Instrument_Name ON T_Storage_Path.SP_path_ID = T_Instrument_Name.IN_storage_path_ID
			    WHERE T_Instrument_Name.IN_name IN ('CBSS_Orb1', 'PrepHPLC1')
			    UNION
			    SELECT T_Storage_Path.SP_path_ID
			    FROM T_Storage_Path INNER JOIN
				     T_Instrument_Name ON T_Storage_Path.SP_path_ID = T_Instrument_Name.IN_source_path_ID
			    WHERE T_Instrument_Name.IN_name IN ('CBSS_Orb1', 'PrepHPLC1')
			    UNION
			    SELECT DISTINCT T_Storage_Path.SP_path_ID
			    FROM T_Dataset INNER JOIN
			         T_Storage_Path ON T_Dataset.DS_storage_path_ID = T_Storage_Path.SP_path_ID))
			  )

		DELETE T_EMSL_DMS_Instrument_Mapping
		FROM T_EMSL_DMS_Instrument_Mapping
			LEFT OUTER JOIN T_Instrument_Name
			    ON T_EMSL_DMS_Instrument_Mapping.DMS_Instrument_ID = T_Instrument_Name.Instrument_ID 
			        AND
			        T_Instrument_Name.IN_Name <> 'CBSS_Orb1'			   

		DELETE FROM T_Prep_LC_Run
	    WHERE ID > 0
  
	    DELETE T_Prep_LC_Column
		WHERE column_name <> 'IgY12_LC10_01'

		DELETE FROM T_Instrument_Name
		WHERE NOT IN_Name IN ('CBSS_Orb1', 'PrepHPLC1', 'DMS_Pipeline_Data')

		UPDATE T_Instrument_Name
		SET IN_status = 'Inactive'
		WHERE IN_name = 'PrepHPLC1'

		DELETE T_Analysis_Tool_Allowed_Instrument_Class
		FROM T_Instrument_Class
		     INNER JOIN T_Analysis_Tool_Allowed_Instrument_Class
		       ON T_Instrument_Class.IN_class = T_Analysis_Tool_Allowed_Instrument_Class.Instrument_Class
		WHERE (NOT (T_Instrument_Class.IN_class IN ('IN_class', 'Agilent_Ion_Trap', 'Agilent_TOF_V2', 
		      'BrukerFT_BAF', 'BrukerMALDI_Imaging_V2', 'BrukerTOF_BAF', 'Data_Folders', 'Finnigan_Ion_Trap',
		      'IMS_Agilent_TOF', 'LTQ_FT', 'Thermo_Exactive', 'Triple_Quad', 'PrepHPLC')))
		
	    DELETE FROM T_Instrument_Operation_History
	    WHERE Instrument <> 'None'

	    DELETE FROM T_Internal_Standards
	    WHERE NOT Name In ('unknown', 'none', 'ADHYeast_031411', 'MP_12_01')

		TRUNCATE TABLE T_LC_Cart_Settings_History

		DELETE FROM T_LC_Cart
	    WHERE NOT Cart_Name IN ('unknown', 'No_Cart')

	    DELETE FROM T_LC_Column
	    WHERE SC_Column_Number <> 'unknown'

		DELETE FROM T_Material_Containers
	    WHERE NOT Tag IN ('na', 'Staging', 'MC-1348') AND 
		      NOT ID IN (SELECT EX_Container_ID FROM T_Experiments)
	   
	    DELETE FROM T_Material_Locations
	    WHERE NOT Tag IN ('None', '-20_Staging') AND Freezer <> '-80 BSF1206A' AND
		      NOT ID IN (SELECT Location_ID FROM T_Material_Containers)
		      
		UPDATE T_MTS_Cached_Data_Status
		SET Refresh_Count = 0,
			Insert_Count = 0,
			Update_Count = 0,
			Delete_Count = 0,
			Last_Refreshed = '8/21/2015 1:00 pm',
			Last_Refresh_Minimum_ID = 0,
			Last_Full_Refresh = '8/21/2015 1:00 pm'

		DELETE FROM T_Organism_DB_File
		WHERE filename <> 'contaminants.fasta'

		DELETE FROM T_Param_Files
		WHERE (NOT (Param_File_Name IN ('MSGFDB_NoEnzyme_NoMods_20ppmParTol.txt',
			  'MSPF_MetOx_STYPhos_LysMethDiMethTriMeth_CysDehydro_NTermAcet_SingleInternalCleavage_10ppm.txt',
			  'MSGFDB_Tryp_MetOx_15ppmParTol.txt',
			  'MODa_PartTryp_CysAlk_iTRAQ_8Plex_Par20ppm_Frag0pt6Da.txt', 'MODPlus_PartTryp_20ppmParTol.xml',
			  'MSGFDB_PartTryp_Dyn_MetOx_K_Ubiq_20ppmParTol.txt', 'MSGFDB_PartTryp_MetOx_50ppmParTol.txt',
			  'MSGFDB_PartTryp_MetOx.txt',
			  'sequest_N14_Tryp_Dyn_MOx_ST_PCGalNAz_Stat_StatCysAlk_Par50ppm_Frag0pt5Da.params',
			  'MSGFDB_PartTryp_DynSTYPhos_Stat_CysAlk_20ppmParTol.txt',
			  'MSGFDB_PartTryp_MetOx_LysAcet_StatCysAlk_10ppmParTol.txt',
			  'PeakPicking_NonThresholded_PeakBR2_SN7.xml', 'MODa_Tryp_CysAlk_Par20ppm_Frag0pt6Da.txt',
			  'MSGFDB_PartTryp_DynMetOx_Stat_CysAlk_iTRAQ_4Plex_20ppmParTol.txt',
			  'MSGFDB_PartTryp_DynMetOx_iTRAQ_4Plex_20ppmParTol.txt',
			  'MSGFDB_Tryp_DynSTYPhos_Stat_CysAlk_20ppmParTol.txt',
			  'MSGFDB_PartTryp_DynSTYPhos_Stat_CysAlk_iTRAQ_8Plex_20ppmParTol.txt',
			  'MSGFDB_Tryp_Stat_CysAlk_10ppmParTol_MaxCS4.txt', 'Biofilm_Drugs_10ppm_2015-04-27.xml',
			  'TIC_Only_2008-11-07.xml', 'MSAlign_DefaultTol_NoMods_NoThreshold_2014-01-24.txt',
			  'MSGFDB_NoEnzyme_DynIAAABP_Cys_50ppmParTol.txt',
			  'MSGFDB_PartTryp_Stat_CysAlk_Dyn_STYPhos_Heavy_Lys_Arg_20ppm.txt',
			  'MSGFDB_Tryp_Dyn_MetOx_ST_PCGalNAz_StatCysAlk_TMT_6Plex_20ppmParTol.txt',
			  'Biofilm_Drugs_30ppm_2015-04-27.xml',
			  'MSGFDB_HighResMSn_NoEnzyme_DynMetOx_ProOx_Stat_CysAlk_20ppmParTol.txt',
			  'MSGFDB_PartTryp_MetOx_StatCysAlk_20ppmParTol.txt', 'Biofilm_Drugs_20ppm_2015-04-27.xml',
			  'DTA_Gen_EmptyParams.txt',
			  'MSGFDB_HighResMSn_PartTryp_DynMetOx_CysNEM_Stat_TMT_6plex_20ppmParTol.txt',
			  'MSGFDB_PartTryp_MetOx_20ppmParTol.txt', 'Default_2005-11-04.xml',
			  'MSGFDB_NoEnzyme_DynMalABPminusH_Cys_50ppmParTol.txt',
			  'FragmentedParameters_Velos_7ppm_DH.txt',
			  'IMS_UIMF_PeakBR4_PeptideBR4_SN3_SumScans4_SumFrames3_noFit_Sat20000_Thrash_WithPeaks_2012-04-20.xml',
			  'MSGFDB_PartTryp_DynMetOx_CysNEM_CysSNEM_20ppmParTol.txt',
			  'MSGFDB_NoEnzyme_DynIAAABPminusH_Cys_50ppmParTol.txt',
			  'MSPF_MetOx_CysDehydro_NTermAcet_SingleInternalCleavage.txt',
			  'sequest_N14_NE_Dyn_Met_Oxy.params',
			  'MSGFDB_PartTryp_DynMetOx_Stat_CysAlk_iTRAQ_4Plex_10ppmParTol.txt',
			  'MSPF_MetOx_STYPhos_LysMethDiMethTriMeth_NTermAcet_CysTriOx_SingleInternalCleavage_10ppm.txt',
			  'Default_2008-08-22.xml', 'LTQ_Orb_SN2_PeakBR2_PeptideBR1_Thrash_Sum3.xml',
			  'MSGFDB_PartTryp_DynSTYPhos_Stat_CysAlk_TMT_6Plex_Protocol1_20ppmParTol.txt',
			  'MSGFDB_PartArgC_MetOx_StatCysAlk_20ppmParTol.txt',
			  'MSGFDB_PartTryp_DynMetOx_Stat_CysAlk_iTRAQ_8Plex_20ppmParTol.txt',
			  'MSGFDB_Tryp_Dyn_MetOx_ST_DBCO_GalNAz_StatCysAlk_20ppmParTol.txt',
			  'MSGFDB_PartTryp_DynMetOx_Stat_TMT_6Plex_20ppmParTol.txt',
			  'xtandem_Rnd1Tryp_StatCysAlk_Dyn2xO18_100ppmParent_MaxCS4_Max2MC.xml',
			  'IMS_UIMF_PeakBR4_PeptideBR4_SN3_SumScans9_NoLCSum_noFit_Sat20000_Thrash_2013-07-24.xml',
			  '12T_Natacha_SiWu_2007-16-07.Par', 'LTQ_FT_Lipidomics_2012-04-16.xml',
			  'MSGFDB_PartTryp_DynMetOx_CysNEM_CysSSG_20ppmParTol.txt',
			  'MSGFDB_TOF_PartTryp_MetOx_50ppmParTol.txt',
			  'LTQ_Orb_SN2_PeakBR2_PeptideBR1_Thrash_Sum3_IncludeMSMS.xml',
			  'sequest_HCD_N14_Tryp_Dyn_MOx_ST_PCGalNAz_Stat_StatCysAlk_Par50ppm.params',
			  'xtandem_Rnd1PartTryp_Rnd2DynMetOx.xml', 'MSGFDB_PartTryp_MetOx_StatCysAlk.txt',
			  'MSGFDB_PartTryp_NoMods_20ppmParTol.txt',
			  'TMT10_LTQ-FT_10ppm_ReporterTol0.003Da_2014-08-06.xml',
			  'LTQ_Orb_USTags_MS2_THRASH_WithPeaks_Relaxed_MaxMW25K.xml',
			  'MSGFDB_Tryp_NoMods_20ppmParTol.txt',
			  'MSPF_MetOx_STYPhos_LysMethDiMethTriMeth_NTermAcet_CysTriOx_NoInternalCleavage_10ppm.txt',
			  'MSGFDB_NoEnzyme_DynMalABP_TEV_Cys_50ppmParTol.txt',
			  'MSGFDB_Tryp_Stat_CysAlk_20ppmParTol_MaxCS4.txt',
			  'MSPF_MetOx_MetDiOx_LysMethDiMethTriMeth_NTermAcet_CysTriOx_SingleInternalCleavage_10ppm.txt',
			  'MSGFDB_NoEnzyme_DynMetOx_10ppmParTol.txt',
			  'MSGFDB_PartTryp_DynSTYPhos_NTerm_Myristoyl_20ppmParTol.txt',
			  'IMS_UIMF_SmallMolecules_PeakBR6_PeptideBR3_SN3_Sum7Scans_NoLCSum_Sat50000_2015-03-26.xml',
			  'MSGFDB_Tryp_TMT_6Plex_20ppmParTol.txt',
			  'Inspect_Unrestrictive_FTHybrid_ParTol10ppm_FragTol20ppm.txt', 'SMAQC_2014-01-08.xml',
			  'MSGFDB_PartTryp_DynMetOx_CysNEM_CysSulfinicSulfonic_20ppmParTol.txt',
			  'MODPlus_Tryp_20ppmParTol.xml', 'MSGFDB_NoEnzyme_DynIAAABP_TEVminusH_Cys_50ppmParTol.txt',
			  'MSGFDB_NoEnzyme_DynMalABP_TEVminusH_Cys_50ppmParTol.txt',
			  'PeakPicking_NonThresholded_PeakBR5_SN7.xml',
			  'sequest_HCD_N14_PartTryp_DynMetOx_Stat_Cys_Iodo_ITRAQ_8PLEX_Par50ppmFrag0pt05Da.params',
			  'MSGFDB_PartTryp_MetOx_NTermAcet_StatCysAlk_10ppmParTol.txt',
			  'LTQ_FT_Metabolomics_2007-08-10.xml',
			  'IMS_UIMF_PeakBR6_PeptideBR6_SN3_Sum7Scans_NoLCSum_Sat50000_2013-09-06.xml',
			  'MSGFDB_PartTryp_Dyn_MW_Ox_NQR_Deamide_Stat_CysAlk_iTRAQ_8Plex_7ppmParTol.txt',
			  'MSGFDB_C13_N15_PartTryp_20ppmParTol.txt',
			  'MSGFDB_PartAspN_DynMetOx_CysNEM_CysAlk_20ppmParTol.txt',
			  'MSGFDB_PartTryp_DynMetOx_CysNEM_CysAlk_20ppmParTol.txt',
			  'ProMex_Charge2to60_Mass3000to50000.txt',
			  'NOMSI_DI_Diagnostics_Targets_Pairs_2015-04-30.param',
			  'MSGFDB_PartAspN_MetOx_StatCysAlk_20ppmParTol.txt',
			  'MSGFDB_NoEnzyme_DynIAAABP_TEV_Cys_50ppmParTol.txt',
			  'TMT6_LTQ-FT_10ppm_ReporterTol0.015Da_2014-08-06.xml',
			  'MSGFDB_PartTryp_MetOx_10ppmParTol_IsotopeError-3,2.txt',
			  'Relaxed_HiResMSMS_TopDown_2010-06-08.PAR',
			  'MASIC_OGlcNAc_Fragments_10ppm_0.01DaReporter_2013-11-17.xml',
			  'ITRAQ_LTQ-FT_10ppm_ReporterTol0.015Da_2014-08-06.xml',
			  'MSGFDB_PartTryp_Dyn_MetOx_ST_PCGalNAz_StatCysAlk_TMT_6Plex_20ppmParTol.txt',
			  'MSAlign_15ppm_0pt01_FDR_2012-01-03.txt', 'MSGFDB_PartTryp_MetOx_10ppmParTol.txt',
			  'MSGFDB_PartTryp_DynMetOx_Stat_CysAlk_TMT_6Plex_10ppmParTol.txt',
			  'MSGFDB_Tryp_DynSTYPhos_Stat_CysAlk_iTRAQ_4Plex_10ppmParTol.txt',
			  'MSGFDB_PartTryp_MetOx_StatCysAlk_10ppmParTol.txt',
			  'Intact_Orbitrap_SN5_Threshold10_2014-01-20.par', 'MODa_PartTryp_Par20ppm_Frag0pt6Da.txt',
			  'sequest_N14_PartTryp_Dyn_MetOx_10ppmParTol_0pt5FragTol.params',
			  'MSGFDB_PartTryp_DynMetOx_CysNEM_20ppmParTol.txt', 'LTQ_Orb_SN2_PeakBR2_PeptideBR2.xml',
			  'MSGFDB_PartTryp_MetOx_NTermMetLossAcetyl_StatCysAlk_10ppmParTol.txt',
			  'MSGFDB_PartTryp_DynSTYPhos_Stat_CysAlk_TMT_6Plex_20ppmParTol.txt',
			  'MSGFDB_NoEnzyme_MetOx_50ppmParTol.txt',
			  'MSGFDB_PartTryp_Dyn_MetOx_NLinked3_4_5_6Man_2GlcNAc_20ppmParTol.txt',
			  'MSGFDB_PartTryp_StatCysAlk_20ppmParTol.txt',
			  'sequest_N14_PartTryp_Dyn_MetOx_Stat_CysAlk_10ppmParTol_0pt5FragTol.params',
			  'ITRAQ8_LTQ-FT_10ppm_ReporterTol0.015Da_2014-08-06.xml',
			  'MSGFDB_PartTryp_DynMetOx_Stat_CysAlk_TMT_6Plex_20ppmParTol.txt',
			  'LTQ_Orb_USTags_MS2_THRASH_WithPeaks_Relaxed.xml', 'LTQ-FT_10ppm_2014-08-06.xml',
			  'MSGFDB_PartTryp_Stat_CysAlk_Dyn_Heavy_Lys_Arg_20ppm.txt',
			  'IMS_UIMF_PeakBR2_PeptideBR3_SN3_Sum7Scans_NoLCSum_Sat50000_2013-09-06.xml',
			  'MSGFDB_PartTryp_DynSTYPhos_Stat_CysAlk_iTRAQ_4Plex_20ppmParTol.txt',
			  'MSGFDB_NoEnzyme_DynMalABP_Cys_50ppmParTol.txt')))

		DELETE T_Param_File_Mass_Mods
		FROM T_Param_File_Mass_Mods LEFT OUTER JOIN
		   T_Param_Files ON T_Param_File_Mass_Mods.Param_File_ID = T_Param_Files.Param_File_ID
		WHERE (T_Param_Files.Param_File_ID IS NULL)

		DELETE T_Param_Entries
		FROM T_Param_Entries LEFT OUTER JOIN
		   T_Param_Files ON T_Param_Entries.Param_File_ID = T_Param_Files.Param_File_ID
		WHERE (T_Param_Files.Param_File_ID IS NULL)

	    DELETE FROM T_Predefined_Analysis
	    WHERE AD_Enabled = 0

		DELETE FROM T_Predefined_Analysis
		WHERE (AD_campaignNameCriteria <> 'QC-Shew-Standard')

      	DELETE FROM T_Instrument_Class
		WHERE NOT IN_Class IN ('IN_class', 'Agilent_Ion_Trap', 'Agilent_TOF_V2', 'BrukerFT_BAF',
			'BrukerMALDI_Imaging_V2', 'BrukerTOF_BAF', 'Data_Folders', 'Finnigan_Ion_Trap',
			'IMS_Agilent_TOF', 'LTQ_FT', 'Thermo_Exactive', 'Triple_Quad', 'PrepHPLC')

		DELETE T_Instrument_Data_Type_Name
		FROM T_Instrument_Class
			RIGHT OUTER JOIN T_Instrument_Data_Type_Name
				ON T_Instrument_Class.raw_data_type = T_Instrument_Data_Type_Name.Raw_Data_Type_Name
		WHERE (T_Instrument_Class.IN_class IS NULL)

		DELETE FROM T_Instrument_Group_Allowed_DS_Type
		WHERE NOT IN_Group IN ('Agilent_GC-MS', 'Agilent_TOF_V2', 'Bruker_FTMS', 'Bruker_QTOF',
	      'DataFolders', 'Exactive', 'GC-TSQ', 'IMS', 'LTQ', 'LTQ-ETD', 'LTQ-FT', 'LTQ-Prep',
	      'MALDI-Imaging', 'Orbitrap', 'QExactive', 'TSQ', 'VelosOrbi')

		DELETE FROM T_Instrument_Group
		WHERE NOT IN_Group IN ('Agilent_GC-MS', 'Agilent_TOF_V2', 'Bruker_FTMS', 'Bruker_QTOF',
	      'DataFolders', 'Exactive', 'GC-TSQ', 'IMS', 'LTQ', 'LTQ-ETD', 'LTQ-FT', 'LTQ-Prep',
	      'MALDI-Imaging', 'Orbitrap', 'QExactive', 'TSQ', 'VelosOrbi', 'PrepHPLC')

	    DELETE FROM T_Sample_Submission
	    WHERE Campaign_ID NOT IN (SELECT Campaign_ID FROM dms5.dbo.T_Campaign where Campaign_Num = 'SWDev')

		DELETE FROM T_Campaign
	    WHERE NOT Campaign_Num in ('Placeholder', 'SWDev', 'CBSS_Orbitrap_Data')

	   	 DELETE FROM T_Research_Team
	    WHERE NOT Team IN ('Placeholder', 'CBSS_Orbitrap_Data', 'SWDev') AND
		      NOT ID IN (SELECT CM_Research_Team FROM T_Campaign)

		DELETE T_Research_Team_Membership
		FROM T_Research_Team
		     RIGHT OUTER JOIN T_Research_Team_Membership
		       ON T_Research_Team.ID = T_Research_Team_Membership.Team_ID
		WHERE (T_Research_Team.Team IS NULL)

	    DELETE FROM T_Sample_Submission
	    WHERE Campaign_ID NOT IN (SELECT Campaign_ID FROM dms5.dbo.T_Campaign where Campaign_Num = 'SWDev')

		DELETE FROM T_Campaign
	    WHERE NOT Campaign_Num in ('Placeholder', 'SWDev', 'CBSS_Orbitrap_Data')

		DELETE FROM T_Secondary_Sep
		WHERE (NOT (SS_name IN ('none', 'LC-ISCO-Standard', 'LC-Agilent', 'LC-ISCO-Special', 'LC-Agilent-Special',
		   'LC-ISCO-Metabolomics_WaterSoluble', 'LC-ISCO-Formic_100minute', 'GC-Agilent-Fiehn', 'LC-Agilent-Formic_100minute',
		   'LC-Agilent-Metabolomics_LipidSoluble', 'LC-Waters-Formic_52min', 'LC-Waters-Formic_100min', 'LC-Eksigent-Formic',
		   'LC-Waters-Formic_40min', 'LC-Waters-Formic_60min', 'LC-Waters-IntactProtein_200min',
		   'LC-Waters-Metabolomics_WaterSoluble', 'LC-Waters-Metabolomics_LipidSoluble', 'Glycans', 'LC-Waters-Formic_3hr',
		   'LC-Waters-Formic_4hr', 'GC-Agilent-FAMEs', 'LC-Unknown', 'LC-Waters-Formic_5hr', 'LC-Agilent-Phospho',
		   'LC-Eksigent-Phospho', 'LC-Waters-Phospho', 'LC-Eksigent-Formic_100min', 'LC-Eksigent-Formic_5hr', 'LC-2D-Custom',
		   'LC-Agilent-Formic_45minute', 'LC-ISCO-Formic_50minute', 'LC-Agilent-Formic_5hr', 'Infusion', 'LC-IMER_100min',
		   'LC-IMER_3hr', 'LC-IMER_5hr', 'LC-Dionex-Formic_100min', 'LC-Vanquish-Formic_100min', 'LC-Vanquish-Formic_60min',
		   'LC-Vanquish-Formic_30min', 'LC-Vanquish-HILIC')))

		DELETE T_Separation_Group
		FROM T_Separation_Group
			 LEFT OUTER JOIN T_Secondary_Sep
			   ON T_Separation_Group.Sep_Group = T_Secondary_Sep.Sep_Group
		WHERE SS_name IS NULL

		DELETE FROM T_Settings_Files
		WHERE (NOT (File_Name IN ('Decon2LS_DefSettings.xml',
		   'Decon2LS_FF_IMS_UseHardCodedFilters_20ppm_NoFlags_ConfDtn_2011-03-30.xml',
		   'Decon2LS_FF_IMS_UseHardCodedFilters_20ppm_NoFlags_ConfDtn_v1.0.4953_2013-07-24.xml',
		   'Decon2LS_FF_IMS4Filters_20ppm_NoFlags_ConfDtn_2011-05-16.xml', 'DTAGen_DeconMSn.xml',
		   'FinniganDefSettings.xml', 'FinniganDefSettings_DeconMSN.xml', 'FinniganDefSettings_DeconMSN_DTARef_NoMods.xml',
		   'FinniganDefSettings_DeconMSN_DTARef_StatCysAlk.xml', 'FTICRDefSettings.txt', 'GlyQIQ_Alditol_No_PSA.xml',
		   'Inspect_IonTrapDefSettings_DeconMSN.xml', 'IonTrapDefSettings_32bit_zlib.xml', 'IonTrapDefSettings_DeconMSN.xml',
		   'IonTrapDefSettings_DeconMSN_25000UpperMH.xml', 'IonTrapDefSettings_DeconMSN_Centroid_Top500.xml',
		   'IonTrapDefSettings_DeconMSN_DTARef_NoMods.xml', 'IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk.xml',
		   'IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_4plexITRAQ.xml',
		   'IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_8plexITRAQ.xml',
		   'IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_phospho.xml',
		   'IonTrapDefSettings_DeconMSN_DTARef_StatCysAlk_TMT6plex.xml', 'IonTrapDefSettings_MSConvert.xml',
		   'IonTrapDefSettings_MSConvert_15Parts_MergeResults_Top1.xml',
		   'IonTrapDefSettings_MSConvert_25Parts_MergeResults_Top1_SkipProteinMods.xml',
		   'IonTrapDefSettings_MSConvert_DTARef_NoMods.xml', 'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk.xml',
		   'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ.xml',
		   'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_4plexITRAQ_phospho.xml',
		   'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_8plexITRAQ.xml',
		   'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_phospho.xml',
		   'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_TMT6plex.xml',
		   'IonTrapDefSettings_MSConvert_DTARef_StatCysAlk_TMT6plex_phospho.xml',
		   'IonTrapDefSettings_MzML_NoRefine.xml', 'IonTrapDefSettings_MzML_StatCysAlk.xml', 'LTQ_FTDefSettings.txt',
		   'LTQ_FTPEK_ProcessMS2.txt', 'MODPlus_MzML.xml', 'MSAlign_Standard.xml',
		   'MSGFDB_DeconMSn_15Parts_MergeResults_Top1.xml', 'MSGFDB_MzXML_Bruker.xml',
		   'MSGFPlus_HPC_DeconMSn.xml', 'MSPF_TopDown_Standard.xml', 'mzML_MSConvert_Centroid_Top5000.xml',
		   'mzXML_Bruker.xml', 'mzXML_Bruker_ProfileMode.xml', 'mzXML_MSConvert_NoCentroid.xml', 'na',
		   'NOMSI_Malak_Transformations.xml', 'ProMex_Bruker_Standard.xml', 'ProMex_TopDown_Standard.xml',
		   'PSI_mzML_MSConvert.xml')))

		TRUNCATE TABLE T_Notification_Entity_User

		
		DELETE FROM T_Users
		WHERE (NOT (ID IN
			   (SELECT ID
			 FROM T_Users
			 WHERE (U_PRN IN ('svc-dms'))
			 UNION
			 SELECT DISTINCT T_Users.ID
			 FROM T_Users INNER JOIN
				T_Dataset ON T_Users.U_PRN = T_Dataset.DS_Oper_PRN INNER JOIN
				T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
			 WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1')
			 UNION
			 SELECT DISTINCT AJR_requestor
			 FROM T_Analysis_Job_Request
			 UNION
			 SELECT Received_by_user_id 
			 FROM T_Sample_Submission
			 UNION
			 SELECT DISTINCT T_Users.ID
			 FROM T_Experiments INNER JOIN
				T_Users ON T_Experiments.EX_researcher_PRN = T_Users.U_PRN INNER JOIN
				T_Instrument_Name INNER JOIN
				T_Dataset ON T_Instrument_Name.Instrument_ID = T_Dataset.DS_instrument_name_ID ON 
				T_Experiments.Exp_ID = T_Dataset.Exp_ID
			 WHERE (T_Instrument_Name.IN_name = 'CBSS_Orb1')))) AND
			 NOT U_PRN IN (
				SELECT CC_Contact_PRN FROM T_Cell_Culture
				UNION
				SELECT CC_PI_PRN FROM T_Cell_Culture)

		DELETE T_User_Operations_Permissions
		FROM T_User_Operations_Permissions LEFT OUTER JOIN
		   T_Users ON T_User_Operations_Permissions.U_ID = T_Users.ID
		WHERE (T_Users.ID IS NULL)

	    DELETE FROM T_Wellplates
	    WHERE WP_Well_Plate_Num <> 'na'

		TRUNCATE TABLE T_Analysis_Job_Processor_Group_Associations
		TRUNCATE TABLE T_Analysis_Job_Processor_Tools
		TRUNCATE TABLE T_Analysis_Job_PSM_Stats
		TRUNCATE TABLE T_Analysis_Job_Status_History
		TRUNCATE TABLE T_Analysis_Status_Monitor_Params
		TRUNCATE TABLE T_Archive_Space_Usage
		
		DELETE FROM T_Attachments
		
		TRUNCATE TABLE T_AuxInfo_Value
		TRUNCATE TABLE T_Cached_Dataset_Folder_Paths
		TRUNCATE TABLE T_Cached_Instrument_Usage_by_Proposal
		TRUNCATE TABLE T_Campaign_Tracking
		TRUNCATE TABLE T_Cell_Culture_Tracking
		TRUNCATE TABLE T_Charge_Code
		TRUNCATE TABLE T_Dataset_Info
		TRUNCATE TABLE T_Dataset_QC
		TRUNCATE TABLE T_Dataset_QC_Curation
		TRUNCATE TABLE T_Dataset_ScanTypes
		TRUNCATE TABLE T_Dataset_Storage_Move_Log
		TRUNCATE TABLE T_EMSL_Instrument_Allocation
		TRUNCATE TABLE T_EMSL_Instrument_Usage_Report
		TRUNCATE TABLE T_Entity_Rename_Log
		
		DELETE FROM T_EUS_Users WHERE PERSON_ID <> 1000
		
		TRUNCATE TABLE T_Event_Log
		TRUNCATE TABLE T_Experiment_Group_Members
		
		TRUNCATE TABLE T_Factor
		TRUNCATE TABLE T_Factor_Log
		TRUNCATE TABLE T_File_Attachment
		TRUNCATE TABLE T_General_Statistics
		TRUNCATE TABLE T_Instrument_Allocation
		TRUNCATE TABLE T_Instrument_Allocation_Updates
		TRUNCATE TABLE T_Instrument_Config_History
		TRUNCATE TABLE T_Instrument_Name_Bkup
		TRUNCATE TABLE T_LC_Cart_Config_History
		TRUNCATE TABLE T_LC_Cart_Version
		TRUNCATE TABLE T_Log_Entries
		TRUNCATE TABLE T_Mass_Correction_Factors_Change_History
		TRUNCATE TABLE T_Material_Log
		TRUNCATE TABLE T_MTS_MT_DB_Jobs_Cached
		TRUNCATE TABLE T_MTS_MT_DBs_Cached
		TRUNCATE TABLE T_MTS_Peak_Matching_Tasks_Cached
		TRUNCATE TABLE T_MTS_PT_DB_Jobs_Cached
		TRUNCATE TABLE T_MTS_PT_DBs_Cached
		TRUNCATE TABLE T_Operations_Tasks
		TRUNCATE TABLE T_Organisms_Change_History
		TRUNCATE TABLE T_Predefined_Analysis_Scheduling_Queue
		TRUNCATE TABLE T_Protein_Collection_Usage
		TRUNCATE TABLE T_Requested_Run_EUS_Users
		TRUNCATE TABLE T_Requested_Run_Status_History
		TRUNCATE TABLE T_Residues_Change_History
		TRUNCATE TABLE T_Run_Interval
		TRUNCATE TABLE T_Sample_Prep_Request_Updates
		TRUNCATE TABLE T_Settings_Files_XML_History
		TRUNCATE TABLE T_Storage_Path_Bkup
		TRUNCATE TABLE T_Usage_Log
		TRUNCATE TABLE T_Usage_Stats

		Select 'Deletion Complete' AS Task
	End
	Else
	Begin
	
		SELECT 'Data would be deleted from a large number of tables' as Msg
		
	End

	-------------------------------------------------
	-- Add back foreign keys
	-------------------------------------------------

	If @infoOnly = 0
	Begin
				
		alter table T_Analysis_Job add
			constraint FK_T_Analysis_Job_T_Dataset foreign key(AJ_datasetID) references T_Dataset(Dataset_ID),
			constraint FK_T_Analysis_Job_T_Analysis_Job_Batches foreign key(AJ_batchID) references T_Analysis_Job_Batches(Batch_ID),
			constraint FK_T_Analysis_Job_T_Analysis_Job_Request foreign key(AJ_requestID) references T_Analysis_Job_Request(AJR_requestID);

		create index IX_T_Analysis_Job_AJ_StateID_AJ_JobID on T_Analysis_Job(AJ_StateID,AJ_jobID);

		create index IX_T_Analysis_Job_DatasetID_JobID_StateID on T_Analysis_Job(AJ_datasetID,AJ_jobID,AJ_StateID);

		create index IX_T_Analysis_Job_StateID_include_JobPriorityToolDataset on T_Analysis_Job(AJ_StateID)
			include(AJ_priority,AJ_jobID,AJ_datasetID,AJ_analysisToolID);

		create index IX_T_Analysis_Job_ToolID_JobID_DatasetID_include_AJStart on T_Analysis_Job(AJ_analysisToolID,AJ_jobID,AJ_datasetID)
			include(AJ_start);

		create index IX_T_Analysis_Job_ToolID_JobID_OrganismID_DatasetID on T_Analysis_Job(AJ_analysisToolID,AJ_jobID,AJ_organismID,AJ_datasetID);

		create index IX_T_Analysis_Job_ToolID_JobID_StateName_DatasetID on T_Analysis_Job(AJ_analysisToolID,AJ_jobID,AJ_StateNameCached,AJ_datasetID);

		create index IX_T_Analysis_Job_AJ_created on T_Analysis_Job(AJ_created);

		create index IX_T_Analysis_Job_AJ_finish on T_Analysis_Job(AJ_finish);

		create index IX_T_Analysis_Job_ToolID_include_DatasetID on T_Analysis_Job(AJ_analysisToolID)
			include(AJ_datasetID);

		create index IX_T_Analysis_Job_OrganismDBName on T_Analysis_Job(AJ_organismDBName);

		create index IX_T_Analysis_Job_AJ_datasetID on T_Analysis_Job(AJ_datasetID);

		create index IX_T_Analysis_Job_RequestID on T_Analysis_Job(AJ_requestID);

		create index IX_T_Analysis_Job_AJ_StateNameCached on T_Analysis_Job(AJ_StateNameCached);

		create index IX_T_Analysis_Job_AJ_Last_Affected on T_Analysis_Job(AJ_Last_Affected);

		create index IX_T_Analysis_Job_ToolID_include_ParmFile on T_Analysis_Job(AJ_analysisToolID)
			include(AJ_parmFileName);

		create index IX_T_Analysis_Job_AJ_ToolNameCached on T_Analysis_Job(AJ_ToolNameCached);

		alter table T_Analysis_Job_Processor_Group_Associations add
			constraint FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job foreign key(Job_ID) references T_Analysis_Job(AJ_jobID) on delete cascade;

		alter table T_Dataset add
			constraint FK_T_Dataset_T_Experiments foreign key(Exp_ID) references T_Experiments(Exp_ID);

		create index IX_T_Dataset_Created on T_Dataset(DS_created);

		create unique index IX_T_Dataset_Dataset_Num on T_Dataset(Dataset_Num);

		create index IX_T_Dataset_Acq_Time_Start on T_Dataset(Acq_Time_Start);

		create index IX_T_Dataset_State_ID on T_Dataset(DS_state_ID);

		create index IX_T_Dataset_Exp_ID on T_Dataset(Exp_ID);

		create index IX_T_Dataset_Dataset_ID_Exp_ID on T_Dataset(Dataset_ID,Exp_ID);

		create index IX_T_Dataset_Dataset_ID_DS_Created on T_Dataset(Dataset_ID,DS_created)
			include(Dataset_Num);

		create index IX_T_Dataset_StoragePathID_Created_ExpID_InstrumentNameID_DatasetID on T_Dataset(DS_storage_path_ID,DS_created,Exp_ID,DS_instrument_name_ID,Dataset_ID);

		create index IX_T_Dataset_ID_Created_ExpID_SPathID_InstrumentNameID on T_Dataset(Dataset_ID,DS_created,Exp_ID,DS_storage_path_ID,DS_instrument_name_ID);

		create index IX_T_Dataset_InstNameID_Dataset_DatasetID on T_Dataset(DS_instrument_name_ID,Dataset_Num,Dataset_ID);

		create index IX_T_Dataset_LC_column_ID on T_Dataset(DS_LC_column_ID);

		create index IX_T_Dataset_DatasetID_Created_StoragePathID_Include_DatasetNum on T_Dataset(Dataset_ID,DS_created,DS_storage_path_ID)
			include(Dataset_Num);

		create index IX_T_Dataset_DatasetID_include_DatasetNum_InstrumentNameID on T_Dataset(Dataset_ID)
			include(Dataset_Num,DS_instrument_name_ID);

		create index IX_T_Dataset_StoragePathID_Created_InstrumentNameID_Rating_DatasetID on T_Dataset(DS_storage_path_ID,DS_created,DS_instrument_name_ID,DS_rating,Dataset_ID);

		create index IX_T_Dataset_InstrumentNameID_TypeID_include_DatasetID on T_Dataset(DS_instrument_name_ID,DS_type_ID)
			include(Dataset_ID);

		create index IX_T_Dataset_DatasetID_InstrumentNameID_StoragePathID on T_Dataset(Dataset_ID,DS_instrument_name_ID,DS_storage_path_ID);

		create index IX_T_Dataset_InstrumentNameID_LastAffected_include_State on T_Dataset(DS_instrument_name_ID,DS_Last_Affected)
			include(DS_state_ID);

		create index IX_T_Dataset_Rating_include_InstrumentID_DatasetID on T_Dataset(DS_rating)
			include(DS_instrument_name_ID,Dataset_ID);

		create index IX_T_Dataset_InstrumentNameID_AcqTimeStart_include_DatasetID_DSRating on T_Dataset(DS_instrument_name_ID,Acq_Time_Start)
			include(Dataset_ID,DS_rating);

		create index IX_T_Dataset_Sec_Sep on T_Dataset(DS_sec_sep)
			include(DS_created,Dataset_ID);

		create index IX_T_Dataset_DateSortKey on T_Dataset(DateSortKey);

		alter table T_Dataset_Archive add
			constraint FK_T_Dataset_Archive_T_Dataset foreign key(AS_Dataset_ID) references T_Dataset(Dataset_ID);

		alter table T_Dataset_Info add
			constraint FK_T_Dataset_Info_T_Dataset foreign key(Dataset_ID) references T_Dataset(Dataset_ID);

		alter table T_Dataset_Storage_Move_Log add
			constraint FK_T_Dataset_Storage_Move_Log_T_Dataset foreign key(DatasetID) references T_Dataset(Dataset_ID);

		alter table T_Experiment_Cell_Cultures add
			constraint FK_T_Experiment_Cell_Cultures_T_Experiments foreign key(Exp_ID) references T_Experiments(Exp_ID);

		alter table T_Experiment_Groups add
			constraint FK_T_Experiment_Groups_T_Experiments foreign key(Parent_Exp_ID) references T_Experiments(Exp_ID);

		alter table T_Experiment_Group_Members add
			constraint FK_T_Experiment_Group_Members_T_Experiments foreign key(Exp_ID) references T_Experiments(Exp_ID);

		alter table T_Instrument_Name add
			constraint FK_T_Instrument_Name_T_storage_path_StoragePathID foreign key(IN_storage_path_ID) references T_Storage_Path(SP_path_ID),
			constraint FK_T_Instrument_Name_T_storage_path_SourcePathID foreign key(IN_source_path_ID) references T_Storage_Path(SP_path_ID);

		alter table T_Param_Entries add
			constraint FK_T_Param_Entries_T_Param_Files foreign key(Param_File_ID) references T_Param_Files(Param_File_ID) on update cascade;

		alter table T_Param_File_Mass_Mods add
			constraint FK_T_Param_File_Mass_Mods_T_Param_Files foreign key(Param_File_ID) references T_Param_Files(Param_File_ID) on update cascade;
	
		ENABLE TRIGGER trig_ud_T_Analysis_Job on T_Analysis_Job;
		ENABLE TRIGGER trig_ud_T_Dataset on T_Dataset;
		ENABLE TRIGGER trig_ud_T_Experiments on T_Experiments;

	End
			
Done:
	If @message <> ''
		Print @message
		
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ClearAllData] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ClearAllData] TO [PNL\D3M580] AS [dbo]
GO
