/****** Object:  Table [dbo].[T_Aux_Info_Target] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Aux_Info_Target](
	[Target_Type_ID] [int] IDENTITY(500,1) NOT NULL,
	[Target_Type_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_Table] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_ID_Col] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Target_Name_Col] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_AuxInfo_Target] PRIMARY KEY CLUSTERED 
(
	[Target_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Aux_Info_Target] TO [DDL_Viewer] AS [dbo]
GO
