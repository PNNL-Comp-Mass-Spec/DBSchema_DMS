/****** Object:  Table [dbo].[T_EUS_Proposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_Proposals](
	[Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Title] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[State_ID] [int] NOT NULL,
	[Import_Date] [datetime] NOT NULL,
	[Proposal_Type] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Proposal_Start_Date] [datetime] NULL,
	[Proposal_End_Date] [datetime] NULL,
	[Last_Affected] [datetime] NULL,
	[Numeric_ID]  AS ([dbo].[ExtractInteger]([Proposal_ID])) PERSISTED,
 CONSTRAINT [PK_T_EUS_Proposals] PRIMARY KEY CLUSTERED 
(
	[Proposal_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_EUS_Proposals] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_EUS_Proposals] TO [DMS_EUS_Admin] AS [dbo]
GO
/****** Object:  Index [IX_T_EUS_Proposals] ******/
CREATE NONCLUSTERED INDEX [IX_T_EUS_Proposals] ON [dbo].[T_EUS_Proposals]
(
	[State_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_EUS_Proposals_Type] ******/
CREATE NONCLUSTERED INDEX [IX_T_EUS_Proposals_Type] ON [dbo].[T_EUS_Proposals]
(
	[Proposal_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_EUS_Proposals] ADD  CONSTRAINT [DF__T_EUS_Pro__PROPO__71A7CADF]  DEFAULT ('') FOR [Proposal_ID]
GO
ALTER TABLE [dbo].[T_EUS_Proposals] ADD  CONSTRAINT [DF_T_EUS_Proposals_State_ID]  DEFAULT (1) FOR [State_ID]
GO
ALTER TABLE [dbo].[T_EUS_Proposals] ADD  CONSTRAINT [DF_T_EUS_Proposals_Import_Date]  DEFAULT (getdate()) FOR [Import_Date]
GO
ALTER TABLE [dbo].[T_EUS_Proposals] ADD  CONSTRAINT [DF_T_EUS_Proposals_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_EUS_Proposals]  WITH CHECK ADD  CONSTRAINT [FK_T_EUS_Proposals_T_EUS_Proposal_State_Name] FOREIGN KEY([State_ID])
REFERENCES [dbo].[T_EUS_Proposal_State_Name] ([ID])
GO
ALTER TABLE [dbo].[T_EUS_Proposals] CHECK CONSTRAINT [FK_T_EUS_Proposals_T_EUS_Proposal_State_Name]
GO
