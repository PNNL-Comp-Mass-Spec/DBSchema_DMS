/****** Object:  Table [dbo].[T_Lab_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Lab_Locations](
	[Lab_ID] [int] IDENTITY(100,1) NOT NULL,
	[Lab_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Lab_Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Lab_Active] [tinyint] NOT NULL,
	[Sort_Weight] [int] NOT NULL,
 CONSTRAINT [PK_T_Lab_Locations] PRIMARY KEY CLUSTERED 
(
	[Lab_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Lab_Locations_Active] ******/
CREATE NONCLUSTERED INDEX [IX_T_Lab_Locations_Active] ON [dbo].[T_Lab_Locations]
(
	[Lab_Active] ASC,
	[Sort_Weight] ASC,
	[Lab_Name] ASC
)
INCLUDE([Lab_Description]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [ix_t_lab_locations_lab_name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [ix_t_lab_locations_lab_name] ON [dbo].[T_Lab_Locations]
(
	[Lab_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Lab_Locations] ADD  CONSTRAINT [DF_T_Lab_Locations_Lab_Description]  DEFAULT ('') FOR [Lab_Description]
GO
ALTER TABLE [dbo].[T_Lab_Locations] ADD  CONSTRAINT [DF_T_Lab_Locations_Lab_Active]  DEFAULT ((1)) FOR [Lab_Active]
GO
ALTER TABLE [dbo].[T_Lab_Locations] ADD  CONSTRAINT [DF_T_Lab_Locations_Sort_Weight]  DEFAULT ((1)) FOR [Sort_Weight]
GO
