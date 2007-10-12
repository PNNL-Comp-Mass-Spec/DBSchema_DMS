/****** Object:  Table [dbo].[T_EUS_Proposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_Proposals](
	[PROPOSAL_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__T_EUS_Pro__PROPO__71A7CADF]  DEFAULT (''),
	[TITLE] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[State_ID] [int] NOT NULL CONSTRAINT [DF_T_EUS_Proposals_State_ID]  DEFAULT (1),
	[Import_Date] [datetime] NOT NULL CONSTRAINT [DF_T_EUS_Proposals_Import_Date]  DEFAULT (getdate()),
 CONSTRAINT [PK_T_EUS_Proposals] PRIMARY KEY NONCLUSTERED 
(
	[PROPOSAL_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_EUS_Proposals] ******/
CREATE CLUSTERED INDEX [IX_T_EUS_Proposals] ON [dbo].[T_EUS_Proposals] 
(
	[State_ID] ASC
) ON [PRIMARY]
GO
GRANT SELECT ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin]
GO
GRANT INSERT ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin]
GO
GRANT DELETE ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Proposals] ([PROPOSAL_ID]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Proposals] ([PROPOSAL_ID]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Proposals] ([TITLE]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Proposals] ([TITLE]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Proposals] ([State_ID]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Proposals] ([State_ID]) TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Proposals] ([Import_Date]) TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Proposals] ([Import_Date]) TO [DMS_EUS_Admin]
GO
ALTER TABLE [dbo].[T_EUS_Proposals]  WITH CHECK ADD  CONSTRAINT [FK_T_EUS_Proposals_T_EUS_Proposal_State_Name] FOREIGN KEY([State_ID])
REFERENCES [T_EUS_Proposal_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_EUS_Proposals] CHECK CONSTRAINT [FK_T_EUS_Proposals_T_EUS_Proposal_State_Name]
GO
