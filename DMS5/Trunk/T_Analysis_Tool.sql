/****** Object:  Table [dbo].[T_Analysis_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Tool](
	[AJT_toolID] [int] NOT NULL,
	[AJT_toolName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJT_paramFileType] [int] NULL,
	[AJT_parmFileStoragePath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_parmFileStoragePathLocal] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_allowedInstClass] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_defaultSettingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_resultType] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_autoScanFolderFlag] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_active] [tinyint] NOT NULL CONSTRAINT [DF_T_Analysis_Tool_AJT_inactive]  DEFAULT (1),
	[AJT_searchEngineInputFileFormats] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_orgDbReqd] [int] NULL,
	[AJT_extractionRequired] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_allowedDatasetTypes] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [T_Analysis_Tool_PK] PRIMARY KEY CLUSTERED 
(
	[AJT_toolID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Trigger [dbo].[trig_iu_T_Analysis_Tool] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger dbo.trig_iu_T_Analysis_Tool on dbo.T_Analysis_Tool
For Insert, Update
/********************************************************
**
**	Desc: 
**		Validates that the Dataset Types and Instrument Classes defined 
**		 for each updated Analysis Tool are defined in T_DatasetTypeName
**		 or T_Instrument_Class
**
**	Auth:	mem
**	Date:	07/25/2007 - Ticket #502
**
*********************************************************/
AS

	If @@RowCount = 0
		Return

	Set NoCount On
	
	declare @myRowCount int
	declare @myError int
	set @myRowCount = 0
	set @myError = 0

	if update(AJT_allowedDatasetTypes) OR
	   update(AJT_allowedInstClass)
	Begin -- <a>
		-- Validate that the dataset types and instrument classes are valid for each updated row in the "inserted" table

		Declare @AllowedDatasetTypes varchar(255)
		Declare @AllowedInstClassees varchar(255)
		Declare @BadItemList varchar(255)
		Declare @ErrorMessage varchar(512)

		Declare @AnalysisToolID int
		Declare @AnalysisToolName varchar(128)

		Declare @continue int

		SELECT @AnalysisToolID = Min(AJT_toolID)-1
		FROM inserted

		Set @continue = 1
		While @continue = 1
		Begin -- <b>
			SELECT TOP 1 @AnalysisToolID = AJT_toolID,
						 @AnalysisToolName = AJT_toolName,
						 @AllowedDatasetTypes = AJT_allowedDatasetTypes,
						 @AllowedInstClassees = AJT_allowedInstClass

			FROM inserted
			WHERE AJT_toolID > @AnalysisToolID
			ORDER BY AJT_toolID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount = 0
				Set @continue = 0
			Else
			Begin -- <c>
				Set @BadItemList = ''
				SELECT @BadItemList = @BadItemList + Item + ','
				FROM (	SELECT DISTINCT Item
						FROM MakeTableFromList(@AllowedDatasetTypes)
					 ) LookupQ LEFT OUTER JOIN
					 T_DatasetTypeName ON LookupQ.Item = T_DatasetTypeName.DST_Name
				WHERE T_DatasetTypeName.DST_Name Is Null

				If Len(@BadItemList) > 0
				Begin
					-- Remove the trailing comma
					Set @BadItemList = Left(@BadItemList, Len(@BadItemList)-1)
					Set @ErrorMessage = 'Error: Invalid dataset types defined: ''' + @BadItemList + ''' for analysis tool ''' + @AnalysisToolName + ''''
					RAISERROR (@ErrorMessage, 16, 1)
					ROLLBACK TRANSACTION
					set @continue = 0
				End

				If @continue <> 0
				Begin -- <e>
					Set @BadItemList = ''
					SELECT @BadItemList = @BadItemList + Item + ','
					FROM (	SELECT DISTINCT Item
							FROM MakeTableFromList(@AllowedInstClassees)
						 ) LookupQ LEFT OUTER JOIN
						 T_Instrument_Class ON LookupQ.Item = T_Instrument_Class.IN_Class
					WHERE T_Instrument_Class.IN_Class Is Null

					If Len(@BadItemList) > 0
					Begin
						-- Remove the trailing comma
						Set @BadItemList = Left(@BadItemList, Len(@BadItemList)-1)
						Set @ErrorMessage = 'Error: Invalid instrument classes defined: ''' + @BadItemList + ''' for analysis tool ''' + @AnalysisToolName + ''''
						RAISERROR (@ErrorMessage, 16, 1)
						ROLLBACK TRANSACTION
						set @continue = 0
					End
				End -- </e>	
			End	-- </c>
		End	-- </b>
	End -- </a>

GO
ALTER TABLE [dbo].[T_Analysis_Tool]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Tool_T_Param_File_Types] FOREIGN KEY([AJT_paramFileType])
REFERENCES [T_Param_File_Types] ([Param_File_Type_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Tool] CHECK CONSTRAINT [FK_T_Analysis_Tool_T_Param_File_Types]
GO
