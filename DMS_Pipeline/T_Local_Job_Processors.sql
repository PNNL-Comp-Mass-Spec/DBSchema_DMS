/****** Object:  Table [dbo].[T_Local_Job_Processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Local_Job_Processors](
	[Job] [int] NOT NULL,
	[Processor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[General_Processing] [int] NOT NULL,
 CONSTRAINT [PK_T_Local_Job_Processors] PRIMARY KEY CLUSTERED 
(
	[Job] ASC,
	[Processor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Local_Job_Processors] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_Local_Job_Processors_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_Local_Job_Processors_Job] ON [dbo].[T_Local_Job_Processors]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
