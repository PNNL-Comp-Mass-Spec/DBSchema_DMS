/****** Object:  Table [dbo].[T_Analysis_Tool] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Tool](
	[AJT_toolID] [int] NOT NULL,
	[AJT_toolName] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJT_toolBasename] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJT_paramFileType] [int] NULL,
	[AJT_parmFileStoragePath] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_parmFileStoragePathLocal] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_defaultSettingsFileName] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_resultType] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_autoScanFolderFlag] [char](3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_active] [tinyint] NOT NULL,
	[AJT_searchEngineInputFileFormats] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_orgDbReqd] [tinyint] NOT NULL,
	[AJT_extractionRequired] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AJT_toolTag] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AJT_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Use_SpecialProcWaiting] [tinyint] NOT NULL,
 CONSTRAINT [T_Analysis_Tool_PK] PRIMARY KEY CLUSTERED 
(
	[AJT_toolID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Analysis_Tool_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Analysis_Tool_Name] ON [dbo].[T_Analysis_Tool] 
(
	[AJT_toolName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
GRANT INSERT ON [dbo].[T_Analysis_Tool] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Analysis_Tool] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Analysis_Tool] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Analysis_Tool]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Tool_T_Param_File_Types] FOREIGN KEY([AJT_paramFileType])
REFERENCES [T_Param_File_Types] ([Param_File_Type_ID])
GO
ALTER TABLE [dbo].[T_Analysis_Tool] CHECK CONSTRAINT [FK_T_Analysis_Tool_T_Param_File_Types]
GO
ALTER TABLE [dbo].[T_Analysis_Tool] ADD  CONSTRAINT [DF_T_Analysis_Tool_AJT_inactive]  DEFAULT ((1)) FOR [AJT_active]
GO
ALTER TABLE [dbo].[T_Analysis_Tool] ADD  CONSTRAINT [DF_T_Analysis_Tool_AJT_orgDbReqd]  DEFAULT ((0)) FOR [AJT_orgDbReqd]
GO
ALTER TABLE [dbo].[T_Analysis_Tool] ADD  CONSTRAINT [DF_T_Analysis_Tool_AJT_extractionRequired]  DEFAULT ('N') FOR [AJT_extractionRequired]
GO
ALTER TABLE [dbo].[T_Analysis_Tool] ADD  CONSTRAINT [DF_T_Analysis_Tool_Use_SpecialProcWaiting]  DEFAULT ((0)) FOR [Use_SpecialProcWaiting]
GO
