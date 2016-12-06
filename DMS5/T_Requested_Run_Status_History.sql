/****** Object:  Table [dbo].[T_Requested_Run_Status_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_Status_History](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Posting_Time] [datetime] NOT NULL,
	[State_ID] [tinyint] NOT NULL,
	[Origin] [varchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Request_Count] [int] NOT NULL,
	[QueueTime_0Days] [int] NULL,
	[QueueTime_1to6Days] [int] NULL,
	[QueueTime_7to44Days] [int] NULL,
	[QueueTime_45to89Days] [int] NULL,
	[QueueTime_90to179Days] [int] NULL,
	[QueueTime_180DaysAndUp] [int] NULL,
 CONSTRAINT [PK_T_Requested_Run_Status_History] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Requested_Run_Status_History] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Requested_Run_Status_History_State_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Requested_Run_Status_History_State_ID] ON [dbo].[T_Requested_Run_Status_History]
(
	[State_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Requested_Run_Status_History]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_Status_History_T_Requested_Run_State_Name] FOREIGN KEY([State_ID])
REFERENCES [dbo].[T_Requested_Run_State_Name] ([State_ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_Status_History] CHECK CONSTRAINT [FK_T_Requested_Run_Status_History_T_Requested_Run_State_Name]
GO
