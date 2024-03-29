/****** Object:  Table [dbo].[T_Step_Tools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Step_Tools](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Shared_Result_Version] [smallint] NOT NULL,
	[Filter_Version] [smallint] NOT NULL,
	[CPU_Load] [smallint] NOT NULL,
	[Uses_All_Cores] [tinyint] NOT NULL,
	[Memory_Usage_MB] [int] NOT NULL,
	[Parameter_Template] [xml] NULL,
	[Available_For_General_Processing] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Param_File_Storage_Path] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Tag] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AvgRuntime_Minutes] [real] NULL,
	[Disable_Output_Folder_Name_Override_on_Skip] [tinyint] NOT NULL,
	[Primary_Step_Tool] [tinyint] NOT NULL,
	[Holdoff_Interval_Minutes] [int] NOT NULL,
 CONSTRAINT [PK_T_Step_Tools_1] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Step_Tools] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Step_Tools_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Step_Tools_Name] ON [dbo].[T_Step_Tools]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Step_Tools_Shared_Result_Version] ******/
CREATE NONCLUSTERED INDEX [IX_T_Step_Tools_Shared_Result_Version] ON [dbo].[T_Step_Tools]
(
	[Shared_Result_Version] ASC
)
INCLUDE([Name],[Disable_Output_Folder_Name_Override_on_Skip]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Shared_Result]  DEFAULT ((0)) FOR [Shared_Result_Version]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Filter_Version]  DEFAULT ((0)) FOR [Filter_Version]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_CPU_Load]  DEFAULT ((1)) FOR [CPU_Load]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Uses_All_Cores]  DEFAULT ((0)) FOR [Uses_All_Cores]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Memory_Usage_MB]  DEFAULT ((250)) FOR [Memory_Usage_MB]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Available_For_General_Processing]  DEFAULT ('Y') FOR [Available_For_General_Processing]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Param_File_Storage_Path]  DEFAULT ('') FOR [Param_File_Storage_Path]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Disable_Output_Folder_Name_Override_on_Skip]  DEFAULT ((0)) FOR [Disable_Output_Folder_Name_Override_on_Skip]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Primary_Step_Tool]  DEFAULT ((0)) FOR [Primary_Step_Tool]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Holdoff_Interval_Minutes]  DEFAULT ((5)) FOR [Holdoff_Interval_Minutes]
GO
