/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Tools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Tools](
	[Tool_ID] [int] NOT NULL,
	[Processor_ID] [int] NOT NULL,
	[Entered] [datetime] NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Tools_Entered]  DEFAULT (getdate()),
	[Entered_By] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Tools_Entered_By]  DEFAULT (suser_sname()),
 CONSTRAINT [PK_T_Analysis_Job_Processor_Tools] PRIMARY KEY CLUSTERED 
(
	[Tool_ID] ASC,
	[Processor_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT UPDATE ON [dbo].[T_Analysis_Job_Processor_Tools] ([Entered_By]) TO [DMS2_SP_User]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Tools]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Tools_T_Analysis_Job_Processors] FOREIGN KEY([Processor_ID])
REFERENCES [T_Analysis_Job_Processors] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Tools] CHECK CONSTRAINT [FK_T_Analysis_Job_Processor_Tools_T_Analysis_Job_Processors]
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Tools]  WITH CHECK ADD  CONSTRAINT [FK_T_Analysis_Job_Processor_Tools_T_Analysis_Tool] FOREIGN KEY([Tool_ID])
REFERENCES [T_Analysis_Tool] ([AJT_toolID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Tools] CHECK CONSTRAINT [FK_T_Analysis_Job_Processor_Tools_T_Analysis_Tool]
GO
