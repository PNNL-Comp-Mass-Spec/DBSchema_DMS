/****** Object:  Table [dbo].[T_Secondary_Sep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Secondary_Sep](
	[SS_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SS_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_Secondary_Sep] PRIMARY KEY NONCLUSTERED 
(
	[SS_ID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Secondary_Sep] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Secondary_Sep] ON [dbo].[T_Secondary_Sep] 
(
	[SS_name] ASC
) ON [PRIMARY]
GO
