/****** Object:  Table [dbo].[T_Instrument_Class] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Class](
	[IN_class] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[is_purgable] [tinyint] NOT NULL CONSTRAINT [DF_T_Instrument_Class_is_purgable]  DEFAULT (0),
	[raw_data_type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Instrument_Class_raw_data_type]  DEFAULT ('na'),
	[requires_preparation] [tinyint] NOT NULL CONSTRAINT [DF_T_Instrument_Class_requires_preparation]  DEFAULT (0),
	[Allowed_Dataset_Types] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Instrument_Class] PRIMARY KEY CLUSTERED 
(
	[IN_class] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Trigger [trig_iu_T_Instrument_Class] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


create Trigger dbo.trig_iu_T_Instrument_Class on dbo.T_Instrument_Class
For Insert, Update
/********************************************************
**
**	Desc: 
**		Validates that the Dataset Types defined for each updated
**		 Instrument Class are defined in T_DatasetTypeName
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

	if update(Allowed_Dataset_Types)
	Begin -- <a>
		-- Validate that the dataset types are valid for each updated row in the "inserted" table

		Declare @AllowedDatasetTypes varchar(255)
		Declare @BadItemList varchar(255)
		Declare @ErrorMessage varchar(512)

		Declare @InClass varchar(64)
		Declare @continue int

		Set @InClass = ''
		Set @continue = 1
		While @continue = 1
		Begin -- <b>
			SELECT TOP 1 @InClass = IN_Class,
						 @AllowedDatasetTypes = Allowed_Dataset_Types
			FROM inserted
			WHERE IN_Class > @InClass
			ORDER BY IN_Class
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
				Begin -- <d>
					-- Remove the trailing comma
					Set @BadItemList = Left(@BadItemList, Len(@BadItemList)-1)
					Set @ErrorMessage = 'Error: Invalid dataset types defined: ''' + @BadItemList + ''' for instrument class ''' + @InClass + ''''
					RAISERROR (@ErrorMessage, 16, 1)
					ROLLBACK TRANSACTION
					set @continue = 0
				End -- </d>			
			End	-- </c>
		End	-- </b>
	End -- </a>

GO
ALTER TABLE [dbo].[T_Instrument_Class]  WITH NOCHECK ADD  CONSTRAINT [CK_T_Instrument_Class] CHECK  (([raw_data_type] = 'biospec_folder' or ([raw_data_type] = 'dot_raw_folder' or ([raw_data_type] = 'dot_wiff_files' or ([raw_data_type] = 'dot_D_folders' or ([raw_data_type] = 'dot_raw_files' or ([raw_data_type] = 'zipped_s_folders' or [raw_data_type] = 'na')))))))
GO
ALTER TABLE [dbo].[T_Instrument_Class] CHECK CONSTRAINT [CK_T_Instrument_Class]
GO
