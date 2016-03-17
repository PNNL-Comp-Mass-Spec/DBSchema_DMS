/****** Object:  Table [dbo].[T_Job_Events] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Events](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[Job] [int] NOT NULL,
	[Target_State] [int] NOT NULL,
	[Prev_Target_State] [int] NOT NULL,
	[Entered] [datetime] NOT NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Job_Events] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT UPDATE ON [dbo].[T_Job_Events] ([Entered_By]) TO [DMS_SP_User] AS [dbo]
GO
/****** Object:  Index [IX_T_Job_Events_Current_State_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Events_Current_State_Job] ON [dbo].[T_Job_Events]
(
	[Prev_Target_State] ASC,
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Events_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Events_Entered] ON [dbo].[T_Job_Events]
(
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Job_Events_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Job_Events_Job] ON [dbo].[T_Job_Events]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Job_Events] ADD  CONSTRAINT [DF_T_Job_Events_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Job_Events] ADD  CONSTRAINT [DF_T_Job_Events_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
