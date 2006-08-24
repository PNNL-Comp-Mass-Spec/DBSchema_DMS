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
 CONSTRAINT [PK_T_Requested_Run_Batches] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Requested_Run_Batches]  WITH CHECK ADD  CONSTRAINT [FK_T_Requested_Run_Batches_T_Users] FOREIGN KEY([Owner])
REFERENCES [T_Users] ([ID])
GO
