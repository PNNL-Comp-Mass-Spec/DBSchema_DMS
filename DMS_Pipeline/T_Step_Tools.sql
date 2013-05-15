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
	[Memory_Usage_MB] [int] NOT NULL,
	[Parameter_Template] [xml] NULL,
	[Available_For_General_Processing] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Param_File_Storage_Path] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Tag] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Step_Tools_1] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Shared_Result]  DEFAULT ((0)) FOR [Shared_Result_Version]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Filter_Version]  DEFAULT ((0)) FOR [Filter_Version]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_CPU_Load]  DEFAULT ((1)) FOR [CPU_Load]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Memory_Usage_MB]  DEFAULT ((250)) FOR [Memory_Usage_MB]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Available_For_General_Processing]  DEFAULT ('Y') FOR [Available_For_General_Processing]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Param_File_Storage_Path]  DEFAULT ('') FOR [Param_File_Storage_Path]
GO
ALTER TABLE [dbo].[T_Step_Tools] ADD  CONSTRAINT [DF_T_Step_Tools_Comment]  DEFAULT ('') FOR [Comment]
GO
