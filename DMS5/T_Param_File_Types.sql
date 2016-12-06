/****** Object:  Table [dbo].[T_Param_File_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_File_Types](
	[Param_File_Type_ID] [int] NOT NULL,
	[Param_File_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Primary_Tool_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Param_File_Types] PRIMARY KEY CLUSTERED 
(
	[Param_File_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Param_File_Types] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
ALTER TABLE [dbo].[T_Param_File_Types] ADD  CONSTRAINT [DF_T_Param_File_Types_Primary_Tool_ID]  DEFAULT ((0)) FOR [Primary_Tool_ID]
GO
ALTER TABLE [dbo].[T_Param_File_Types]  WITH CHECK ADD  CONSTRAINT [FK_T_Param_File_Types_T_Analysis_Tool] FOREIGN KEY([Primary_Tool_ID])
REFERENCES [dbo].[T_Analysis_Tool] ([AJT_toolID])
GO
ALTER TABLE [dbo].[T_Param_File_Types] CHECK CONSTRAINT [FK_T_Param_File_Types_T_Analysis_Tool]
GO
