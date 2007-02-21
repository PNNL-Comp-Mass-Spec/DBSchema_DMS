/****** Object:  Table [dbo].[T_Analysis_Job_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processors](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[State] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processors_State]  DEFAULT ('E'),
	[Processor_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Machine] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Notes] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [T_Analysis_Job_Processors_PK] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_Processors]  WITH CHECK ADD  CONSTRAINT [CK_T_Analysis_Job_Processors_State] CHECK  (([State] = 'D' or [State] = 'E'))
GO
