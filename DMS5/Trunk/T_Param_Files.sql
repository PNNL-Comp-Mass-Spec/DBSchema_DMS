/****** Object:  Table [dbo].[T_Param_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_Files](
	[Param_File_ID] [int] IDENTITY(1,1) NOT NULL,
	[Param_File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Param_File_Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Param_Files_Param_File_Description]  DEFAULT (''),
	[Param_File_Type_ID] [int] NOT NULL,
	[Date_Created] [datetime] NULL CONSTRAINT [DF_T_Param_Files_Date_Created]  DEFAULT (getdate()),
	[Date_Modified] [datetime] NULL CONSTRAINT [DF_T_Param_Files_Date_Modified]  DEFAULT (getdate()),
	[Valid] [smallint] NOT NULL CONSTRAINT [DF_T_Param_Files_Valid]  DEFAULT ((1)),
	[Job_Usage_Count] [int] NULL CONSTRAINT [DF_T_Param_Files_Job_Usage_Count]  DEFAULT ((0)),
 CONSTRAINT [PK_T_Param_Files] PRIMARY KEY CLUSTERED 
(
	[Param_File_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Param_Files_Name_and_TypeID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Param_Files_Name_and_TypeID] ON [dbo].[T_Param_Files] 
(
	[Param_File_Name] ASC,
	[Param_File_Type_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
GRANT DELETE ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin]
GO
GRANT INSERT ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin]
GO
ALTER TABLE [dbo].[T_Param_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_Files_T_Param_File_Types] FOREIGN KEY([Param_File_Type_ID])
REFERENCES [T_Param_File_Types] ([Param_File_Type_ID])
GO
ALTER TABLE [dbo].[T_Param_Files] CHECK CONSTRAINT [FK_T_Param_Files_T_Param_File_Types]
GO
ALTER TABLE [dbo].[T_Param_Files]  WITH NOCHECK ADD  CONSTRAINT [CK_T_Param_Files] CHECK  ((charindex(' ',[Param_File_Name])=(0)))
GO
ALTER TABLE [dbo].[T_Param_Files] CHECK CONSTRAINT [CK_T_Param_Files]
GO
