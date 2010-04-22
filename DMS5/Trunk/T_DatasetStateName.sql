/****** Object:  Table [dbo].[T_DatasetStateName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DatasetStateName](
	[DSS_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Dataset_state_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_DatasetStateName] PRIMARY KEY NONCLUSTERED 
(
	[Dataset_state_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
