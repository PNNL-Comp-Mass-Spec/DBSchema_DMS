/****** Object:  Table [dbo].[T_MAC_Job_Request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MAC_Job_Request](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Request_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requestor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Data_Package_ID] [int] NULL,
	[MT_Database] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Options] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[Scheduled_Job] [int] NULL,
	[Scheduling_Notes] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_MAC_Job_Request] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_MAC_Job_Request] ADD  CONSTRAINT [DF_T_MAC_Job_Request_Created]  DEFAULT (getdate()) FOR [Created]
GO
