/****** Object:  Table [dbo].[T_Signatures] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Signatures](
	[Pattern] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Reference] [int] IDENTITY(10,1) NOT NULL,
	[String] [varchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NULL,
	[Last_Used] [datetime] NULL,
 CONSTRAINT [PK_T_Signatures] PRIMARY KEY CLUSTERED 
(
	[Reference] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Signatures] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Signatures] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Signatures] ON [dbo].[T_Signatures]
(
	[Pattern] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Signatures] ADD  CONSTRAINT [DF_T_Signatures_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
ALTER TABLE [dbo].[T_Signatures] ADD  CONSTRAINT [DF_T_Signatures_Last_Used]  DEFAULT (getdate()) FOR [Last_Used]
GO
