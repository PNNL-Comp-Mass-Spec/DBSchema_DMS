/****** Object:  Table [dbo].[T_Material_Freezers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Material_Freezers](
	[Freezer_ID] [int] IDENTITY(10,1) NOT NULL,
	[Freezer] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Freezer_Tag] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Material_Freezers] PRIMARY KEY CLUSTERED 
(
	[Freezer_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Material_Freezers] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Material_Freezers_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Material_Freezers_Name] ON [dbo].[T_Material_Freezers]
(
	[Freezer] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Material_Freezers_Tag] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Material_Freezers_Tag] ON [dbo].[T_Material_Freezers]
(
	[Freezer_Tag] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Material_Freezers]  WITH CHECK ADD  CONSTRAINT [CK_T_Material_Freezers_Tag_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Freezer_Tag],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Material_Freezers] CHECK CONSTRAINT [CK_T_Material_Freezers_Tag_WhiteSpace]
GO
