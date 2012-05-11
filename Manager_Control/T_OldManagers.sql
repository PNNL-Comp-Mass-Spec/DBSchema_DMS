/****** Object:  Table [dbo].[T_OldManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_OldManagers](
	[M_ID] [int] NOT NULL,
	[M_Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[M_TypeID] [int] NOT NULL,
	[M_ParmValueChanged] [tinyint] NOT NULL,
	[M_ControlFromWebsite] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_OldManagers] PRIMARY KEY CLUSTERED 
(
	[M_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
