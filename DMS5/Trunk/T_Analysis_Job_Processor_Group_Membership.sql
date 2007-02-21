/****** Object:  Table [dbo].[T_Analysis_Job_Processor_Group_Membership] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership](
	[Processor_ID] [int] NOT NULL,
	[Group_ID] [int] NOT NULL,
	[Membership_Enabled] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_Analysis_Job_Processor_Group_Membership_Membership_Enabled]  DEFAULT ('Y'),
 CONSTRAINT [T_Analysis_Job_Processor_Group_Membership_PK] PRIMARY KEY CLUSTERED 
(
	[Processor_ID] ASC,
	[Group_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [T_Analysis_Job_Processor_Group_T_Analysis_Job_Processor_Group_Membership_FK1] FOREIGN KEY([Group_ID])
REFERENCES [T_Analysis_Job_Processor_Group] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [T_Analysis_Job_Processors_T_Analysis_Job_Processor_Group_Membership_FK1] FOREIGN KEY([Processor_ID])
REFERENCES [T_Analysis_Job_Processors] ([ID])
GO
ALTER TABLE [dbo].[T_Analysis_Job_Processor_Group_Membership]  WITH CHECK ADD  CONSTRAINT [CK_T_Analysis_Job_Processor_Group_Membership_Enabled] CHECK  (([Membership_Enabled] = 'N' or [Membership_Enabled] = 'Y'))
GO
