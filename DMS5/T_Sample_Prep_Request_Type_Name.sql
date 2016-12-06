/****** Object:  Table [dbo].[T_Sample_Prep_Request_Type_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Sample_Prep_Request_Type_Name](
	[Request_Type] [varchar](16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Sample_Prep_Request_Type] PRIMARY KEY CLUSTERED 
(
	[Request_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Sample_Prep_Request_Type_Name] TO [DDL_Viewer] AS [dbo]
GO
