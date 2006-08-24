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
 CONSTRAINT [PK_T_Instrument_Class] PRIMARY KEY CLUSTERED 
(
	[IN_class] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Instrument_Class]  WITH NOCHECK ADD  CONSTRAINT [CK_T_Instrument_Class] CHECK  (([raw_data_type] = 'biospec_folder' or ([raw_data_type] = 'dot_raw_folder' or ([raw_data_type] = 'dot_wiff_files' or ([raw_data_type] = 'dot_D_folders' or ([raw_data_type] = 'dot_raw_files' or ([raw_data_type] = 'zipped_s_folders' or [raw_data_type] = 'na')))))))
GO
ALTER TABLE [dbo].[T_Instrument_Class] CHECK CONSTRAINT [CK_T_Instrument_Class]
GO
