/****** Object:  Table [dbo].[T_Spectral_Library_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Spectral_Library_Type](
	[Library_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Library_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Spectral_Library_Type] PRIMARY KEY CLUSTERED 
(
	[Library_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Spectral_Library_Type_Library_Type] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Spectral_Library_Type_Library_Type] ON [dbo].[T_Spectral_Library_Type]
(
	[Library_Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
