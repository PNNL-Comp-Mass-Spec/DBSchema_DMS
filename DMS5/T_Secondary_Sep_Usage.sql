/****** Object:  Table [dbo].[T_Secondary_Sep_Usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Secondary_Sep_Usage](
	[SS_ID] [int] NOT NULL,
	[Usage_Last12Months] [int] NULL,
	[Usage_AllYears] [int] NULL,
	[Most_Recent_Use] [datetime] NULL,
 CONSTRAINT [PK_T_Secondary_Sep_Usage] PRIMARY KEY CLUSTERED 
(
	[SS_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
