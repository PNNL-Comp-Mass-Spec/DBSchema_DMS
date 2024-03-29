/****** Object:  Table [dbo].[T_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Research_Team](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Team] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Collaborators] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Research_Team] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Research_Team]  WITH CHECK ADD  CONSTRAINT [CK_T_Research_Team_TeamName_WhiteSpace] CHECK  (([dbo].[has_whitespace_chars]([Team],(1))=(0)))
GO
ALTER TABLE [dbo].[T_Research_Team] CHECK CONSTRAINT [CK_T_Research_Team_TeamName_WhiteSpace]
GO
