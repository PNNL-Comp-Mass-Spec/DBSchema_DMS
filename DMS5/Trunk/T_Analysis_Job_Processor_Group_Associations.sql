/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Group_Associations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations](
	[Job_ID] [int] NOT NULL,
	[Group_ID] [int] NOT NULL,
	[Entered] [datetime] NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Associations_Entered]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Associations_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [PK_T_Analysis_Job_Processor_Group_Associations] PRIMARY KEY CLUSTERED 
(
	[Job_ID] ASC,
	[Group_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job] FOREIGN KEY([Job_ID])
REFERENCES [T_Analysis_Job] ([AJ_jobID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations] CHECK CONSTRAINT [FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job_Processor_Group] FOREIGN KEY([Group_ID])
REFERENCES [T_Analysis_Job_Processor_Group] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Associations] CHECK CONSTRAINT [FK_T_Analysis_Job_Processor_Group_Associations_T_Analysis_Job_Processor_Group]
GO
