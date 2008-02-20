/****** Object:  Table [dbo].[T_LC_Column_State_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_LC_Column_State_Name](
	[LCS_ID] [int] NOT NULL,
	[LCS_Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_LC_Column_State_Name] PRIMARY KEY CLUSTERED 
(
	[LCS_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
