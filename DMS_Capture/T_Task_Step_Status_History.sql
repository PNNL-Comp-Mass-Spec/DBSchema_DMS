/****** Object:  Table [dbo].[T_Task_Step_Status_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Task_Step_Status_History](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Posting_Time] [datetime] NOT NULL,
	[Step_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[State] [tinyint] NOT NULL,
	[Step_Count] [int] NOT NULL,
 CONSTRAINT [PK_T_Task_Step_Status_History] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Task_Step_Status_History] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Task_Step_Status_History_State] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Step_Status_History_State] ON [dbo].[T_Task_Step_Status_History]
(
	[State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Task_Step_Status_History_Step_Tool] ******/
CREATE NONCLUSTERED INDEX [IX_T_Task_Step_Status_History_Step_Tool] ON [dbo].[T_Task_Step_Status_History]
(
	[Step_Tool] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Task_Step_Status_History] ADD  CONSTRAINT [DF_T_Task_Step_Status_History_Posting_Time]  DEFAULT (getdate()) FOR [Posting_Time]
GO
