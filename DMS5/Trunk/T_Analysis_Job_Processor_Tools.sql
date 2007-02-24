/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Tools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Tools](
	[Tool_ID] [int] NOT NULL,
	[Processor_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Analysis_Job_Processor_Tools] PRIMARY KEY CLUSTERED 
(
	[Tool_ID] ASC,
	[Processor_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Tools]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Tools_T_Analysis_Job_Processors] FOREIGN KEY([Processor_ID])
REFERENCES [T_Analysis_Job_Processors] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Tools]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Tools_T_Analysis_Tool] FOREIGN KEY([Tool_ID])
REFERENCES [T_Analysis_Tool] ([AJT_toolID])
GO
