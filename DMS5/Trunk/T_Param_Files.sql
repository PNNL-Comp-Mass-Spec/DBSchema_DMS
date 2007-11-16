/****** Object:  Table [dbo].[T_Param_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_Files](
	[Param_File_ID] [int] IDENTITY(1,1) NOT NULL,
	[Param_File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Param_File_Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Param_File_Type_ID] [int] NULL,
	[Date_Created] [datetime] NULL CONSTRAINT [DF_T_Param_Files_Date_Created]  DEFAULT (getdate()),
	[Date_Modified] [datetime] NULL CONSTRAINT [DF_T_Param_Files_Date_Modified]  DEFAULT (getdate()),
	[Valid] [smallint] NOT NULL CONSTRAINT [DF_T_Param_Files_Valid]  DEFAULT (1),
 CONSTRAINT [PK_T_Param_Files] PRIMARY KEY CLUSTERED 
(
	[Param_File_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

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
ALTER TABLE [dbo].[T_Param_Files]  WITH NOCHECK ADD  CONSTRAINT [CK_T_Param_Files] CHECK  ((charindex(' ',[Param_File_Name]) = 0))
GO
ALTER TABLE [dbo].[T_Param_Files] CHECK CONSTRAINT [CK_T_Param_Files]
GO
