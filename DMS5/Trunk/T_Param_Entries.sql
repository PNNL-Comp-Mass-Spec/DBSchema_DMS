/****** Object:  Table [dbo].[T_Param_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_Entries](
	[Param_Entry_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Entry_Sequence_Order] [int] NULL,
	[Entry_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entry_Specifier] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entry_Value] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Param_File_ID] [int] NULL,
 CONSTRAINT [PK_T_Param_Entries] PRIMARY KEY CLUSTERED 
(
	[Param_Entry_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin]
GO
GRANT INSERT ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin]
GO
GRANT DELETE ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_Entries] ([Param_Entry_ID]) TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] ([Param_Entry_ID]) TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_Entries] ([Entry_Sequence_Order]) TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] ([Entry_Sequence_Order]) TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_Entries] ([Entry_Type]) TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] ([Entry_Type]) TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_Entries] ([Entry_Specifier]) TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] ([Entry_Specifier]) TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_Entries] ([Entry_Value]) TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] ([Entry_Value]) TO [DMS_ParamFile_Admin]
GO
GRANT SELECT ON [dbo].[T_Param_Entries] ([Param_File_ID]) TO [DMS_ParamFile_Admin]
GO
GRANT UPDATE ON [dbo].[T_Param_Entries] ([Param_File_ID]) TO [DMS_ParamFile_Admin]
GO
ALTER TABLE [dbo].[T_Param_Entries]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_Entries_T_Param_Files] FOREIGN KEY([Param_File_ID])
REFERENCES [T_Param_Files] ([Param_File_ID])
ON UPDATE CASCADE
GO
