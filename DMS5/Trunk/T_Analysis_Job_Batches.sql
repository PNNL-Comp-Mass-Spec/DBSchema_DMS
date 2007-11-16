/****** Object:  Table [dbo].[T_Analysis_Job_Batches] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Batches](
	[Batch_ID] [int] IDENTITY(1000,1) NOT NULL,
	[Batch_Created] [datetime] NOT NULL CONSTRAINT [DF_T_Analysis_Job_Batches_Batch_Created]  DEFAULT (getdate()),
	[Batch_Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Analysis_Job_Batches] PRIMARY KEY NONCLUSTERED 
(
	[Batch_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
