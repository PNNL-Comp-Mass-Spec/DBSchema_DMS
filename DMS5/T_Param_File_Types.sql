/****** Object:  Table [dbo].[T_Param_File_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Param_File_Types](
	[Param_File_Type_ID] [int] NOT NULL,
	[Param_File_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Param_File_Types] PRIMARY KEY CLUSTERED 
(
	[Param_File_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Param_File_Types] TO [DMS_ParamFile_Admin] AS [dbo]
GO
