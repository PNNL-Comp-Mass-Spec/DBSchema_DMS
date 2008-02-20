/****** Object:  Table [dbo].[T_Analysis_State_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_State_Name](
	[AJS_stateID] [int] NOT NULL,
	[AJS_name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [T_Analysis_State_Name_PK] PRIMARY KEY CLUSTERED 
(
	[AJS_stateID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
