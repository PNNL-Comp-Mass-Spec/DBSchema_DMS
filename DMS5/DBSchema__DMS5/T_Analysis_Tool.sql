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
 CONSTRAINT [T_Analysis_Tool_PK] PRIMARY KEY CLUSTERED 
(
	[AJT_toolID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Tool]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Tool_T_Param_File_Types] FOREIGN KEY([AJT_paramFileType])
REFERENCES [T_Param_File_Types] ([Param_File_Type_ID])
GO
