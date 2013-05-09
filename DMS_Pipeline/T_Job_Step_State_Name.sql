/****** Object:  Table [dbo].[T_Job_Step_State_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Step_State_Name](
	[ID] [tinyint] NOT NULL,
	[Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Step_State] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
