/****** Object:  Table [dbo].[T_Param_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_Files](
	[Param_File_ID] [int] IDENTITY(1,1) NOT NULL,
	[Param_File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Param_File_Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Param_File_Type_ID] [int] NOT NULL,
	[Date_Created] [datetime] NULL,
	[Date_Modified] [datetime] NULL,
	[Valid] [smallint] NOT NULL,
	[Job_Usage_Count] [int] NULL,
 CONSTRAINT [PK_T_Param_Files] PRIMARY KEY CLUSTERED 
(
	[Param_File_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Param_Files] TO [DMS_ParamFile_Admin] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Param_Files_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Param_Files_Name] ON [dbo].[T_Param_Files]
(
	[Param_File_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Param_Files] ADD  CONSTRAINT [DF_T_Param_Files_Param_File_Description]  DEFAULT ('') FOR [Param_File_Description]
GO
ALTER TABLE [dbo].[T_Param_Files] ADD  CONSTRAINT [DF_T_Param_Files_Date_Created]  DEFAULT (getdate()) FOR [Date_Created]
GO
ALTER TABLE [dbo].[T_Param_Files] ADD  CONSTRAINT [DF_T_Param_Files_Date_Modified]  DEFAULT (getdate()) FOR [Date_Modified]
GO
ALTER TABLE [dbo].[T_Param_Files] ADD  CONSTRAINT [DF_T_Param_Files_Valid]  DEFAULT ((1)) FOR [Valid]
GO
ALTER TABLE [dbo].[T_Param_Files] ADD  CONSTRAINT [DF_T_Param_Files_Job_Usage_Count]  DEFAULT ((0)) FOR [Job_Usage_Count]
GO
ALTER TABLE [dbo].[T_Param_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_Files_T_Param_File_Types] FOREIGN KEY([Param_File_Type_ID])
REFERENCES [dbo].[T_Param_File_Types] ([Param_File_Type_ID])
GO
ALTER TABLE [dbo].[T_Param_Files] CHECK CONSTRAINT [FK_T_Param_Files_T_Param_File_Types]
GO
ALTER TABLE [dbo].[T_Param_Files]  WITH CHECK ADD  CONSTRAINT [CK_T_Param_Files] CHECK  ((charindex(' ',[Param_File_Name])=(0)))
GO
ALTER TABLE [dbo].[T_Param_Files] CHECK CONSTRAINT [CK_T_Param_Files]
GO
ALTER TABLE [dbo].[T_Param_Files]  WITH CHECK ADD  CONSTRAINT [CK_T_Param_Files_ParamFileName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Param_File_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Param_Files] CHECK CONSTRAINT [CK_T_Param_Files_ParamFileName_WhiteSpace]
GO
