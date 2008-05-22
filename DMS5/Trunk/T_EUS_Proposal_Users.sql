/****** Object:  Table [dbo].[T_EUS_Proposal_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_Proposal_Users](
	[Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Person_ID] [int] NOT NULL,
	[Of_DMS_Interest] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_T_EUS_Proposal_Users_Of_DMS_Interest]  DEFAULT ('Y'),
 CONSTRAINT [PK_T_EUS_Proposal_Users] PRIMARY KEY CLUSTERED 
(
	[Proposal_ID] ASC,
	[Person_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_EUS_Proposal_Users] TO [DMS_EUS_Admin]
GO
GRANT INSERT ON [dbo].[T_EUS_Proposal_Users] TO [DMS_EUS_Admin]
GO
GRANT SELECT ON [dbo].[T_EUS_Proposal_Users] TO [DMS_EUS_Admin]
GO
GRANT UPDATE ON [dbo].[T_EUS_Proposal_Users] TO [DMS_EUS_Admin]
GO
ALTER TABLE [dbo].[T_EUS_Proposal_Users]  WITH NOCHECK ADD  CONSTRAINT [FK_T_EUS_Proposal_Users_T_EUS_Proposals] FOREIGN KEY([Proposal_ID])
REFERENCES [T_EUS_Proposals] ([PROPOSAL_ID])
GO
ALTER TABLE [dbo].[T_EUS_Proposal_Users] CHECK CONSTRAINT [FK_T_EUS_Proposal_Users_T_EUS_Proposals]
GO
ALTER TABLE [dbo].[T_EUS_Proposal_Users]  WITH NOCHECK ADD  CONSTRAINT [FK_T_EUS_Proposal_Users_T_EUS_Users] FOREIGN KEY([Person_ID])
REFERENCES [T_EUS_Users] ([PERSON_ID])
GO
ALTER TABLE [dbo].[T_EUS_Proposal_Users] CHECK CONSTRAINT [FK_T_EUS_Proposal_Users_T_EUS_Users]
GO
