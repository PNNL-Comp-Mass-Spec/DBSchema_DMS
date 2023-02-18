/****** Object:  Table [dbo].[T_Cached_Requested_Run_Batch_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Requested_Run_Batch_Stats](
	[Batch_ID] [int] NOT NULL,
	[Requests] [int] NULL,
	[Separation_Group_First] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Separation_Group_Last] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active_Requests] [int] NULL,
	[First_Active_Request] [int] NULL,
	[Last_Active_Request] [int] NULL,
	[Oldest_Request_Created] [datetime] NULL,
	[Oldest_Active_Request_Created] [datetime] NULL,
	[Datasets] [int] NULL,
	[Instrument_First] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Last] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Days_In_Queue] [int] NULL,
	[Min_Days_In_Queue] [int] NULL,
	[Max_Days_In_Queue] [int] NULL,
	[Days_in_Prep_Queue] [int] NULL,
	[Blocked] [int] NULL,
	[Block_Missing] [int] NULL,
	[Last_Affected] [datetime] NULL,
 CONSTRAINT [PK_T_Cached_Requested_Run_Batch_Stats] PRIMARY KEY CLUSTERED 
(
	[Batch_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Cached_Requested_Run_Batch_Stats] ADD  CONSTRAINT [DF_T_Cached_Requested_Run_Batch_Stats_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_Cached_Requested_Run_Batch_Stats]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Requested_Run_Batch_Stats_T_Requested_Run_Batches] FOREIGN KEY([Batch_ID])
REFERENCES [dbo].[T_Requested_Run_Batches] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Cached_Requested_Run_Batch_Stats] CHECK CONSTRAINT [FK_T_Cached_Requested_Run_Batch_Stats_T_Requested_Run_Batches]
GO
