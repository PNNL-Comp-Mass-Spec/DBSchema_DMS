/****** Object:  Table [dbo].[T_DatasetArchiveStateName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DatasetArchiveStateName](
	[DASN_StateID] [int] NOT NULL,
	[DASN_StateName] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_DatasetArchiveStateName] PRIMARY KEY NONCLUSTERED 
(
	[DASN_StateID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
