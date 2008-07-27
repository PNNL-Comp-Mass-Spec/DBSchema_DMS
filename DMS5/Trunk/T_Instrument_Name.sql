/****** Object:  Table [dbo].[T_Instrument_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Name](
	[IN_name] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_ID] [int] NOT NULL,
	[IN_class] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_source_path_ID] [int] NULL,
	[IN_storage_path_ID] [int] NULL,
	[IN_capture_method] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_status] [char](8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Instrument_Name_IN_status]  DEFAULT ('active'),
	[IN_default_CDburn_sched] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_Room_Number] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_Description] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IN_usage] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Instrument_Name_IN_usage]  DEFAULT (''),
	[IN_operations_role] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Instrument_Name_IN_operations_role]  DEFAULT ('Unknown'),
	[IN_max_simultaneous_captures] [smallint] NOT NULL CONSTRAINT [DF_T_Instrument_Name_IN_capture_count_max]  DEFAULT (1),
	[IN_Max_Queued_Datasets] [smallint] NOT NULL CONSTRAINT [DF_T_Instrument_Name_IN_max_queued_datasets]  DEFAULT (1),
	[IN_Capture_Exclusion_Window] [real] NOT NULL CONSTRAINT [DF_T_Instrument_Name_IN_capture_exclusion_window]  DEFAULT (11),
	[IN_Capture_Log_Level] [tinyint] NOT NULL CONSTRAINT [DF_T_Instrument_Name_IN_capture_log_level]  DEFAULT (1),
 CONSTRAINT [PK_T_Instrument_Name] PRIMARY KEY NONCLUSTERED 
(
	[Instrument_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Instrument_Name]  WITH CHECK ADD  CONSTRAINT [FK_T_Instrument_Name_T_Instrument_Class] FOREIGN KEY([IN_class])
REFERENCES [T_Instrument_Class] ([IN_class])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Instrument_Name]  WITH CHECK ADD  CONSTRAINT [CK_T_Instrument_Name] CHECK  (([IN_operations_role] = 'Unused' or ([IN_operations_role] = 'QC' or ([IN_operations_role] = 'Research' or ([IN_operations_role] = 'Production' or [IN_operations_role] = 'Unknown')))))
GO
