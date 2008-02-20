/****** Object:  Table [dbo].[T_Requested_Run_Batches] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Requested_Run_Batches](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Batch] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner] [int] NULL,
	[Created] [datetime] NOT NULL CONSTRAINT [DF_T_Requested_Run_Batches_Created]  DEFAULT (getdate()),
	[Locked] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Requested_Run_Batches_Locking]  DEFAULT ('Yes'),
	[Last_Ordered] [datetime] NULL,
	[Requested_Batch_Priority] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Requested_Run_Batches_Requested_Batch_Priority]  DEFAULT ('Normal'),
	[Actual_Batch_Priority] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Completion_Date] [smalldatetime] NULL,
	[Justification_for_High_Priority] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requested_Instrument] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Requested_Run_Batches_Requested_Instrument]  DEFAULT ('na'),
 CONSTRAINT [PK_T_Requested_Run_Batches] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write]
GO
GRANT INSERT ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write]
GO
GRANT REFERENCES ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Requested_Run_Batches] TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches]  WITH NOCHECK ADD  CONSTRAINT [FK_T_Requested_Run_Batches_T_Users] FOREIGN KEY([Owner])
REFERENCES [T_Users] ([ID])
GO
ALTER TABLE [dbo].[T_Requested_Run_Batches] CHECK CONSTRAINT [FK_T_Requested_Run_Batches_T_Users]
GO
