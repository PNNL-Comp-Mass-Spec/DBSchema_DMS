/****** Object:  Table [dbo].[T_EUS_Proposal_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EUS_Proposal_Type](
	[Proposal_Type] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Proposal_Type_Name] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Abbreviation] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_EUS_Proposal_Type] PRIMARY KEY CLUSTERED 
(
	[Proposal_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_EUS_Proposal_Type] TO [DDL_Viewer] AS [dbo]
GO
