/****** Object:  Table [dbo].[T_Peptide_Synopsis_Reports_State] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Peptide_Synopsis_Reports_State](
	[State_ID] [int] NOT NULL,
	[State_Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Peptide_Synopsis_Reports_State] PRIMARY KEY CLUSTERED 
(
	[State_ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
