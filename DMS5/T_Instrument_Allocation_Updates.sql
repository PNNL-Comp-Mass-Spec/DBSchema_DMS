/****** Object:  Table [dbo].[T_Instrument_Allocation_Updates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Instrument_Allocation_Updates](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Allocation_Tag] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Fiscal_Year] [int] NULL,
	[Allocated_Hours_Old] [float] NULL,
	[Allocated_Hours_New] [float] NULL,
	[Comment] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
	[Entered_By] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Instrument_Allocation_Updates] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Instrument_Allocation_Updates_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_Instrument_Allocation_Updates_Entered] ON [dbo].[T_Instrument_Allocation_Updates] 
(
	[Entered] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Instrument_Allocation_Updates_Proposal_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Instrument_Allocation_Updates_Proposal_ID] ON [dbo].[T_Instrument_Allocation_Updates] 
(
	[Proposal_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Instrument_Allocation_Updates] ADD  CONSTRAINT [DF_T_Instrument_Allocation_Updates_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Instrument_Allocation_Updates] ADD  CONSTRAINT [DF_T_Instrument_Allocation_Updates_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Instrument_Allocation_Updates] ADD  CONSTRAINT [DF_T_Instrument_Allocation_Updates_Entered_By]  DEFAULT (suser_sname()) FOR [Entered_By]
GO
