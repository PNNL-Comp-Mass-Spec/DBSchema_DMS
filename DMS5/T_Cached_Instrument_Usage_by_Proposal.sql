/****** Object:  Table [dbo].[T_Cached_Instrument_Usage_by_Proposal] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Cached_Instrument_Usage_by_Proposal](
	[IN_Group] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Actual_Hours] [float] NULL,
 CONSTRAINT [PK_T_Cached_Instrument_Usage_by_Proposal] PRIMARY KEY CLUSTERED 
(
	[IN_Group] ASC,
	[EUS_Proposal_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Cached_Instrument_Usage_by_Proposal] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Usage_by_Proposal]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Instrument_Usage_by_Proposal_T_EUS_Proposals] FOREIGN KEY([EUS_Proposal_ID])
REFERENCES [dbo].[T_EUS_Proposals] ([Proposal_ID])
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Usage_by_Proposal] CHECK CONSTRAINT [FK_T_Cached_Instrument_Usage_by_Proposal_T_EUS_Proposals]
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Usage_by_Proposal]  WITH CHECK ADD  CONSTRAINT [FK_T_Cached_Instrument_Usage_by_Proposal_T_Instrument_Group] FOREIGN KEY([IN_Group])
REFERENCES [dbo].[T_Instrument_Group] ([IN_Group])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Cached_Instrument_Usage_by_Proposal] CHECK CONSTRAINT [FK_T_Cached_Instrument_Usage_by_Proposal_T_Instrument_Group]
GO
