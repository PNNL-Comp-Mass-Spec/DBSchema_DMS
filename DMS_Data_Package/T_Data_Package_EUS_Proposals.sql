/****** Object:  Table [dbo].[T_Data_Package_EUS_Proposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Package_EUS_Proposals](
	[Data_Package_ID] [int] NOT NULL,
	[Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Item Added] [datetime] NOT NULL,
	[Package Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Data_Package_EUS_Proposals] PRIMARY KEY CLUSTERED 
(
	[Data_Package_ID] ASC,
	[Proposal_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT SELECT ON [dbo].[T_Data_Package_EUS_Proposals] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Package_EUS_Proposals] TO [DMS_SP_User] AS [dbo]
GO
ALTER TABLE [dbo].[T_Data_Package_EUS_Proposals]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_EUS_Proposals_T_Data_Package] FOREIGN KEY([Data_Package_ID])
REFERENCES [T_Data_Package] ([ID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_Data_Package_EUS_Proposals] CHECK CONSTRAINT [FK_T_Data_Package_EUS_Proposals_T_Data_Package]
GO
ALTER TABLE [dbo].[T_Data_Package_EUS_Proposals] ADD  CONSTRAINT [DF_T_Data_Package_EUS_Proposals_Item Added]  DEFAULT (getdate()) FOR [Item Added]
GO
ALTER TABLE [dbo].[T_Data_Package_EUS_Proposals] ADD  CONSTRAINT [DF_T_Data_Package_EUS_Proposals_Package Comment]  DEFAULT ('') FOR [Package Comment]
GO
