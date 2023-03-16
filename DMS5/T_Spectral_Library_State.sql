/****** Object:  Table [dbo].[T_Spectral_Library_State] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Spectral_Library_State](
	[Library_State_ID] [int] IDENTITY(1,1) NOT NULL,
	[Library_State] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Spectral_Library_State] PRIMARY KEY CLUSTERED 
(
	[Library_State_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Spectral_Library_State_Library_State] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Spectral_Library_State_Library_State] ON [dbo].[T_Spectral_Library_State]
(
	[Library_State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
