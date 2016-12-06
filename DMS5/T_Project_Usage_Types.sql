/****** Object:  Table [dbo].[T_Project_Usage_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Project_Usage_Types](
	[Project_Type_ID] [tinyint] NOT NULL,
	[Project_Type_Name] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Project_Usage_Types] PRIMARY KEY CLUSTERED 
(
	[Project_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Project_Usage_Types] TO [DDL_Viewer] AS [dbo]
GO
