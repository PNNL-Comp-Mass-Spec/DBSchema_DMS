/****** Object:  Table [dbo].[T_Job_Request_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Job_Request_Log](
	[Event_ID] [int] IDENTITY(1,1) NOT NULL,
	[Job] [int] NULL,
	[Step] [int] NULL,
	[Processor] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Entered] [datetime] NOT NULL,
	[ReturnCode] [int] NULL,
	[Message] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Num_Tools] [int] NULL,
	[Num_Candidates] [int] NULL,
 CONSTRAINT [PK_T_Job_Request_Log] PRIMARY KEY CLUSTERED 
(
	[Event_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Job_Request_Log] ADD  CONSTRAINT [DF_T_Job_Request_Log_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
